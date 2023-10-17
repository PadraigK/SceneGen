//
//  String+Extensions.swift
//  Created by Padraig O Cinneide on 2023-10-12.
//

import Foundation

extension String {
    func dropPrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }

    func swiftName() -> String {
        if self == uppercased() {
            lowercased()
        } else {
            lowercaseFirstLetter()
        }
    }

    func snakeToCamelcase() -> String {
        let parts = split(separator: "_")

        guard let firstItem = parts.first else {
            return ""
        }

        return String(firstItem).swiftName() +
            parts.dropFirst().map { String($0).uppercaseFirstLetter() }.joined()
    }

    private func lowercaseFirstLetter() -> String {
        if let firstLetter = first {
            firstLetter.lowercased() + dropFirst()
        } else {
            self
        }
    }

    private func uppercaseFirstLetter() -> String {
        if let firstLetter = first {
            firstLetter.uppercased() + dropFirst()
        } else {
            self
        }
    }
}

extension [String] {
    func swiftName() -> String {
        map { $0.swiftName() }.joined(separator: "_")
    }
}
