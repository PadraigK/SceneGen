//
//  Rendering.swift
//
//
//  Created by Padraig O Cinneide on 2023-10-09.
//

import SwiftSyntax
import SwiftSyntaxBuilder

/*
 This syntax code gets hard to follow easily. We can mitigate that by
 following these patterns:

 1. Process the data you need for input separately from the actual
    rendering. The renderer should just take a simple model with everything
    neatly arranged for it to output.
 2. Use private extensions to extract boilerplate, especially when it's
    repeated in a few places.
 3. When writing these private extensions, try to accept arguments that
    are concrete types, like `TypeSyntax`, instead of protocols like
    `TypeSyntaxProtocol`. This will allow you to leverage
    `ExpressibleByStringLiteral` so you can just pass a string at the
    call-site.
 4. As much as possible, keep the `SwiftSyntax` bits quarantined to this one
    file. Don't return/take as input any SwiftSyntax types except in private
    functions.
 5. Don't go to extremes to specify everything as granularly as possible. When
    dropping in a utility function with no interpolation, favour using
    DeclSyntax().
 */

private extension ImportDeclSyntax {
    /// A helper to generate a standard import header and file comment
    static func standardHeader(originText: String = "") -> ImportDeclSyntax {
        ImportDeclSyntax(
            leadingTrivia: [
                .lineComment("// generated by SceneGen \(originText) - do not edit directly"),
                .newlines(2),
            ],
            path: [.init(name: "SwiftGodot")]
        )
    }
}

private extension ExtensionDeclSyntax {
    static func conform(type: TypeSyntax, to conformType: TypeSyntax) -> ExtensionDeclSyntax {
        ExtensionDeclSyntax(
            leadingTrivia: .newline,
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: [InheritedTypeSyntax(type: conformType)]
            )
        ) {}
    }
}

extension InputPropertyName {
    func variableName() -> String {
        rawValue.snakeToCamelcase()
    }
}

enum Renderer {
    /// Renders typed keys for settings like InputMaps
    static func renderInputNames(inputNames: [InputPropertyName]) throws -> SourceFile {
        let source = try SourceFileSyntax {
            ImportDeclSyntax.standardHeader()

            try ExtensionDeclSyntax(leadingTrivia: .newline, extendedType: "InputActionName" as TypeSyntax as TypeSyntax) {
                for inputName in inputNames {
                    try VariableDeclSyntax(
                        "static let \(raw: inputName.variableName()) = Self(\"\(raw: inputName.rawValue)\")"
                    )
                }
            }

            try StructDeclSyntax(
                leadingTrivia: .newlines(2),
                name: "InputActionName"
            ) {
                DeclSyntax("let rawValue: StringName")

                try InitializerDeclSyntax("init(_ rawValue: StringName)") {
                    ExprSyntax("self.rawValue = rawValue")
                }
            }

            ExtensionDeclSyntax.conform(type: "InputActionName", to: "Equatable")

            ExtensionDeclSyntax(leadingTrivia: .newline, extendedType: "Input" as TypeSyntax) {
                DeclSyntax(
                    """
                    static func isActionPressed(_ action: InputActionName) -> Bool {
                        isActionPressed(action: action.rawValue)
                    }
                    """
                )
                DeclSyntax(
                    """
                    static func isActionJustPressed(_ action: InputActionName) -> Bool {
                        isActionJustPressed(action: action.rawValue)
                    }
                    """
                )
                DeclSyntax(
                    """
                    static func getAxis(negative: InputActionName, positive: InputActionName) -> Double {
                        getAxis(negativeAction: negative.rawValue, positiveAction: positive.rawValue)
                    }
                    """
                )
            }

            ExtensionDeclSyntax(leadingTrivia: .newline, extendedType: "InputEvent" as TypeSyntax) {
                DeclSyntax(
                    """
                    func isActionPressed(_ action: InputActionName) -> Bool {
                        isActionPressed(action: action.rawValue)
                    }
                    """
                )
            }
        }

        return .init(
            text: source.formatted().description,
            fileName: "InputMapHelpers.swift"
        )
    }

    /// Renders shared code that is used by other renderers
    static func renderSharedCode() throws -> SourceFile {
        let source = SourceFileSyntax {
            ImportDeclSyntax.standardHeader()

            ProtocolDeclSyntax(name: "NodeProtocol") {
                DeclSyntax("init()")
            }

            ExtensionDeclSyntax.conform(type: "Node", to: "NodeProtocol")
        }

        return .init(
            text: source.formatted().description,
            fileName: "SceneGenShared.swift"
        )
    }

    /// Renders the swift code from a SceneDescription
    static func renderExtension(_ sceneDescription: SceneDescription) throws -> SourceFile {
        let groupedByNodeType = Dictionary(grouping: sceneDescription.outlets, by: { $0.typeName })

        let animationPlayers = groupedByNodeType["AnimationPlayer", default: []]
            .map {
                AnimationPlayerDescription(
                    playerPath: $0.nodePath.joined(),
                    playerSwiftName: $0.swiftName,
                    animationNames: $0.options
                )
            }
        
        // Sort the keys so that we generate deterministically
        let nodeGroups = groupedByNodeType
            .map { (nodeType: $0, outlets: $1) }
            .sorted { $0.nodeType > $1.nodeType }

        let source = try SourceFileSyntax {
            ImportDeclSyntax.standardHeader(originText: "from \(sceneDescription.filePath)")

            try ExtensionDeclSyntax(
                leadingTrivia: .newline,
                extendedType: TypeSyntax(stringLiteral: sceneDescription.type)
            ) {
                try StructDeclSyntax(
                    leadingTrivia: .newlines(1),
                    name: "NodeAccessor<NodeType: NodeProtocol>"
                ) {
                    try VariableDeclSyntax("let path: String")

                    try InitializerDeclSyntax("init(_ path: String)") {
                        ExprSyntax("self.path = path")
                    }
                }

                DeclSyntax(
                    """
                    func node<NodeType: NodeProtocol>(_ nodeAccessor: NodeAccessor<NodeType>) -> NodeType {
                        guard let node = getNodeOrNull(path: .init(stringLiteral: nodeAccessor.path)) else {
                            GD.pushError("Tried to access \\(nodeAccessor.path) on \\(description) but no node was found at that path.")
                            return NodeType()
                        }

                        guard let node = node as? NodeType else {
                            GD.pushError("Tried to access \\(nodeAccessor.path) on \\(description) but the item at that path is a \\(node), not a \\(NodeType.self)")
                            return NodeType()
                        }

                        return node
                    }
                    """
                )

                try VariableDeclSyntax("public static let resourcePath = \"\(raw: sceneDescription.filePath)\"")

                for animationPlayer in animationPlayers {
                    try StructDeclSyntax(leadingTrivia: .newlines(2), name: "\(raw: animationPlayer.playerPath)AnimationName") {
                        DeclSyntax("let rawValue: StringName")

                        try InitializerDeclSyntax("init(_ rawValue: StringName)") {
                            ExprSyntax("self.rawValue = rawValue")
                        }
                    }
                }
            }

            for (nodeType, outlets) in nodeGroups {
                try ExtensionDeclSyntax(
                    leadingTrivia: .newlines(2),
                    extendedType: TypeSyntax("\(raw: sceneDescription.type).NodeAccessor<\(raw: nodeType)>")
                ) {
                    for item in outlets {
                        try VariableDeclSyntax(
                            "static let \(raw: item.swiftName) = Self(\"\(raw: item.nodePath.joined(separator: "/"))\")"
                        )
                    }
                }
            }

            for animationPlayer in animationPlayers {
                let animationNameType = TypeSyntax("\(raw: sceneDescription.type).\(raw: animationPlayer.playerPath)AnimationName")

                ExtensionDeclSyntax.conform(type: animationNameType, to: "Equatable")

                try ExtensionDeclSyntax(leadingTrivia: .newlines(2), extendedType: animationNameType) {
                    for animationName in animationPlayer.animationNames {
                        try VariableDeclSyntax("static let \(raw: animationName.snakeToCamelcase()) = Self(\"\(raw: animationName)\")")
                    }
                }

                ExtensionDeclSyntax(
                    leadingTrivia: .newlines(2),
                    extendedType: TypeSyntax(stringLiteral: sceneDescription.type)
                ) {
                    DeclSyntax(
                        """
                        func playAnimation(_ named: \(animationNameType)) {
                        	node(.\(raw: animationPlayer.playerSwiftName)).play(name: named.rawValue)
                        }
                        """
                    )
                }
            }
        }

        return .init(
            text: source.formatted().description,
            fileName: "\(sceneDescription.type)+SceneInterface.swift"
        )
    }
}
