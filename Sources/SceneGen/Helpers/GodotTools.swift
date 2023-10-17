//
//  GodotTools.swift
//
//
//  Created by Padraig O Cinneide on 2023-10-12.
//

import SwiftGodot
import SwiftGodotKit

struct GodotTools {
    enum Errors: Error {
        case couldntLoadScene
    }

    static func loadScene(projectRelativePath: String) throws -> PackedScene {
        guard let scene = ResourceLoader.load(
            path: "res://\(projectRelativePath)", cacheMode: .reuse
        ) as? PackedScene else {
            throw Errors.couldntLoadScene
        }

        return scene
    }

    /// Runs the callback inside a godot project environment.
    ///  - Note: If a GDExtension in the project crashes, this will also crash but it will happen after the callback has been run, so you can probably ignore it.
    static func runInGodot(projectPath: String, callback: @escaping (SceneTree) -> Int32) {
        runGodot(
            args: ["--headless", "--quiet", "--path", projectPath],
            initHook: { _ in },
            loadScene: { $0.quit(exitCode: callback($0)) },
            loadProjectSettings: { _ in }
        )
    }
}
