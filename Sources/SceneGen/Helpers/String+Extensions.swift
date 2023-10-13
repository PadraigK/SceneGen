//
//  String+Extensions.swift
//  Created by Padraig O Cinneide on 2023-10-12.
//

import Foundation

extension String {
    func swiftName() -> String {
        if self == uppercased() {
            lowercased()
        } else {
            withFirstLetterLowercased()
        }
    }

    func snakeToCamelcase() -> String {
        split(separator: "_").map { String($0).swiftName() }.joined()
    }

    private func withFirstLetterLowercased() -> String {
        if let firstLetter = first {
            firstLetter.lowercased() + dropFirst()
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
