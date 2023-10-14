//
//  SceneDescription.swift
//
//
//  Created by Padraig O Cinneide on 2023-10-12.
//

import Foundation
import SwiftGodot

struct SceneDescription {
    enum Errors: Error {
        case noStateOnScene
        case noNodesInScene
        case notACustomNode
        case inheritedScene
    }

    let name: String
    let type: String
    let filePath: String
    let outlets: [Outlet]

    init(_ scene: PackedScene) throws {
        guard let state = scene.getState() else {
            throw Errors.noStateOnScene
        }

        // The 0 node is always the root one.
        name = state.getNodeName(idx: 0).description
        type = state.getNodeType(idx: 0).description

        if type.isEmpty {
            // This is an inherited scene, so we'll skip it because
            // there's no type to extend. May need to return to this
            // if inherited scenes can have their own SwiftGodot sub-
            // classes.
            throw Errors.inheritedScene
        }
        // Awful hack to detect if this is a scene that we want
        // to generate an extension on or not.
        if NSClassFromString("SwiftGodot.\(type)") != nil {
            throw Errors.notACustomNode
        }

        filePath = scene.resourcePath
        outlets = Array(state.childOutlets(pathPrefix: []).dropFirst())
    }
}

private extension SceneState {
    func childOutlets(pathPrefix: [String]) -> [Outlet] {
        let nodeCount = getNodeCount()

        guard nodeCount > 0 else {
            return []
        }

        var results: [Outlet] = []

        for nodeIndex in 0 ..< nodeCount {
            let path = pathPrefix + getNodePath(idx: nodeIndex)
                .getConcatenatedNames()
                .description
                .dropFirst(2) // removes the leading "./"
                .split(separator: "/")
                .map { String($0) }

            let type = getNodeType(idx: nodeIndex)

            let swiftNamePath: [String]

            // Support the Access as Unique Name feature
            // https://docs.godotengine.org/en/stable/tutorials/scripting/scene_unique_nodes.html
            if isUniqueNameInOwner(at: nodeIndex) {
                swiftNamePath = pathPrefix + [
                    getNodeName(idx: nodeIndex).description,
                ]
            } else {
                swiftNamePath = path
            }

            if type.isEmpty() {
                // This means its an instance of a scene defined in another file
                // so we'll dig in and get the node tree there too
                if let nestedState = getNodeInstance(idx: nodeIndex)?.getState() {
                    results += nestedState.childOutlets(pathPrefix: path)
                } else {
                    Log.error("Couldn't get type at path: \(path)")
                }
            } else {
                // could make this _always_ generate any libraries we find instead of
                // pinning to this node type ??
                let options = if type == "AnimationPlayer" {
                    animationList(at: nodeIndex)
                } else {
                    [String]()
                }
                results.append(
                    .init(
                        nodePath: path,
                        swiftName: swiftNamePath.swiftName(),
                        typeName: type.description,
                        options: options
                    )
                )
            }
        }

        return results
    }
}
