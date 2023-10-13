import ArgumentParser
import Foundation
import SwiftGodot
import SwiftGodotKit

@main
struct SceneGen: ParsableCommand {
    @Argument(help: "The path to a folder with a project.godot file")
    var projectPath: String

    @Argument(help: "The location to place the generated code.")
    var outputPath: String

    mutating func run() throws {
        let projectUrl = URL(filePath: projectPath, directoryHint: .isDirectory)
        let outputUrl = URL(filePath: outputPath, directoryHint: .isDirectory)

        do {
            try resetOutputFolder(outputUrl: outputUrl)
        } catch {
            Log.error("Error resetting output folder at \(outputUrl.absoluteString). \(error)")
            print("Error resetting output folder at \(outputUrl.absoluteString). \(error)")
            throw ExitCode.failure
        }

        let scenePaths = FileManager.default.findFiles(
            withExtensions: ["tscn", "escn"],
            inDirectory: projectUrl
        ).compactMap {
            projectUrl.relativePath(to: $0)
        }

        GodotTools.runInGodot(projectPath: projectPath) { _ in
            for path in scenePaths {
                do {
                    try Renderer.renderExtension(
                        SceneDescription(
                            GodotTools.loadScene(
                                projectRelativePath: path
                            )
                        )
                    )
                    .writeToFolder(outputUrl)
                } catch {
                    print("Failed to generate code for file: \(path). \(error)")
                    Log.error("Error generating swift for file: \(path, privacy: .public). \(error)")
                }
                Log.info("Generated extension for \(path, privacy: .public)")
            }

            do {
                try Renderer.renderSharedCode().writeToFolder(outputUrl)
                Log.info("Generated shared code.")
            } catch {
                print("Failed to generate shared code. \(error)")
                Log.error("Error generating and writing shared code to \(outputUrl, privacy: .public): \(error)")
                return ExitCode.failure.rawValue
            }

            Log.info("Finished generating.")
            return ExitCode.success.rawValue
        }
    }

    private func resetOutputFolder(outputUrl: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: outputPath) {
            Log.info("Removing existing folder.")
            try fm.removeItem(atPath: outputPath)
        }

        Log.info("Creating output folder.")
        try fm.createDirectory(
            atPath: outputPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
