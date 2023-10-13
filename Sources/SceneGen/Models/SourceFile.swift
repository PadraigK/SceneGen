//
//  SourceFile.swift
//
//
//  Created by Padraig O Cinneide on 2023-10-12.
//

import Foundation

struct SourceFile {
    let text: String
    let fileName: String

    func writeToFolder(_ folderUrl: URL) throws {
        let data = text.data(using: .utf8)
        let outputFile = folderUrl.appendingPathComponent(fileName)
        try data?.write(to: outputFile, options: .atomic)
    }
}
