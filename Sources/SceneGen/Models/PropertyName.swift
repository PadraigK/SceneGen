//
//  PropertyName.swift
//
//
//  Created by Padraig O Cinneide on 2023-10-17.
//

import Foundation

/// Represents a ProjectSettings property name
struct PropertyName {
    let rawValue: String
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    var isInput: Bool {
        rawValue.hasPrefix("input/")
    }

    /// Some properties are variants of a root type adds `.macos` / `.windows` suffixes
    /// for each platform. Generally we should ignore them as godot just uses them as platform
    /// specific triggers for e.g. Inputs and in our game code we will just receive the root type.
    var hasPlatformSpecifier: Bool {
        rawValue.contains(".")
    }
}

/// Represents a ProjectSettings input name
struct InputPropertyName {
    let rawValue: String
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Returns nil if the property is not an input
    init?(_ propertyName: PropertyName) {
        guard propertyName.isInput, !propertyName.hasPlatformSpecifier else {
            return nil
        }
        rawValue = propertyName.rawValue.dropPrefix("input/")
    }
}
