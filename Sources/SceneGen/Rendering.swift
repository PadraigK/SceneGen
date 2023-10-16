//
//  Generator.swift
//
//
//  Created by Padraig O Cinneide on 2023-10-09.
//

import SwiftSyntax
import SwiftSyntaxBuilder

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
    static func conform(
        type: some TypeSyntaxProtocol,
        to conformType: some TypeSyntaxProtocol
    ) -> ExtensionDeclSyntax {
        ExtensionDeclSyntax(
            leadingTrivia: .newline,
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: [InheritedTypeSyntax(type: conformType)]
            )
        ) {}
    }
}

enum Renderer {
    /// Renders typed keys for settings like InputMaps
    static func renderProjectSettingsNames(propertyNames: [String]) throws -> SourceFile {
        let source = try SourceFileSyntax {
            ImportDeclSyntax.standardHeader()
            
            // InputMap adds .macos / .windows etc for custom inputs for each
            // platform, but in code, you only reference the root and don't worry
            // about it, so we won't generate any with a "."
            let inputNames = propertyNames
                .filter { $0.hasPrefix("input/") }
                .filter { !$0.contains(".") }
                .map { $0.dropPrefix("input/") }
            
            try ExtensionDeclSyntax(leadingTrivia: .newline, extendedType: "InputActionName" as TypeSyntax as TypeSyntax) {
                
                for inputName in inputNames {
                    let variableName = inputName
                        .snakeToCamelcase()
                    
                    try VariableDeclSyntax(
                        "static let \(raw: variableName) = Self(\"\(raw: inputName)\")"
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
        
            ExtensionDeclSyntax.conform(type: "InputActionName" as TypeSyntax, to: "Equatable" as TypeSyntax)
            
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
            
            ExtensionDeclSyntax.conform(type: "Node" as TypeSyntax, to: "NodeProtocol" as TypeSyntax)
        }

        return .init(
            text: source.formatted().description,
            fileName: "SceneGenShared.swift"
        )
    }

    private static func importHeader(originText: String = "") -> some DeclSyntaxProtocol {
        ImportDeclSyntax(
            leadingTrivia: [
                .lineComment("// generated by SceneGen from \(originText) - do not edit directly"),
                .newlines(2),
            ],
            path: [.init(name: "SwiftGodot")]
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

            for (nodeType, outlets) in groupedByNodeType {
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
                
                ExtensionDeclSyntax.conform(type: animationNameType, to: "Equatable" as TypeSyntax)
                
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
