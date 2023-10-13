//
//  FileManager+Extensions.swift
//
//
//  Created by Padraig O Cinneide on 2023-10-09.
//

import Foundation

extension URL {
    /// Returns the relative path from the receiver to the destinationURL.
    func relativePath(to destinationURL: URL) -> String? {
        let sourceComponents = pathComponents
        let destinationComponents = destinationURL.pathComponents

        let commonPrefixCount = zip(sourceComponents, destinationComponents).prefix(while: { $0.0 == $0.1 }).count

        let relativeComponents = Array(repeating: "..", count: sourceComponents.count - commonPrefixCount) + destinationComponents.suffix(from: commonPrefixCount)

        if relativeComponents.isEmpty {
            return "."
        } else {
            return relativeComponents.joined(separator: "/")
        }
    }
}

extension FileManager {
    /// Finds files with the provided extensions. Recursively searches child directories
    ///  - Note: Hidden directories, and directories containing a `.gdignore` file are skipped along with their descentents.
    func findFiles(
        withExtensions targetExtension: [String],
        inDirectory directoryURL: URL
    ) -> [URL] {
        var foundFiles: [URL] = []

        do {
            let directoryContents = try contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [
                    .skipsHiddenFiles,
                    .skipsPackageDescendants,
                ]
            )

            for item in directoryContents {
                if item.hasDirectoryPath {
                    // Check if the directory should be ignored
                    if !shouldIgnoreDirectory(item) {
                        foundFiles.append(
                            contentsOf: findFiles(withExtensions: targetExtension, inDirectory: item)
                        )
                    }
                } else {
                    // Check if the file has the desired extension
                    if targetExtension.contains(item.pathExtension) {
                        foundFiles.append(item)
                    }
                }
            }
        } catch {
            Log.error("Error while enumerating files: \(error.localizedDescription)")
        }

        return foundFiles
    }

    private func shouldIgnoreDirectory(_ directoryURL: URL) -> Bool {
        // Check if the directory is hidden or contains a .gdignore file
        let gdignorePath = directoryURL.appendingPathComponent(".gdignore").path
        return fileExists(atPath: gdignorePath)
    }
}
