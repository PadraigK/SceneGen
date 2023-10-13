//
//  SwiftGodot+Extensions.swift
//  Created by Padraig O Cinneide on 2023-10-12.
//

import Foundation
import SwiftGodot

/// A strongly typed helper to wrap property names.
struct NodeProperty {
    let rawValue: StringName
    init(_ rawValue: StringName) { self.rawValue = rawValue }

    static let libraries = Self("libraries")
    static let uniqueNameInOwner = Self("unique_name_in_owner")
}

/// Helpers to make it easier to read properties off a SceneState.
extension SwiftGodot.SceneState {
    func getNodeProperty(_ property: NodeProperty, at nodeIndex: Int32) -> Variant? {
        guard let propertyIndex = getNodePropertyIndex(named: property.rawValue, at: nodeIndex) else {
            return nil
        }
        return getNodePropertyValue(idx: nodeIndex, propIdx: propertyIndex)
    }

    private func getNodePropertyIndex(named name: StringName, at nodeIndex: Int32) -> Int32? {
        for propIndex in 0 ..< getNodePropertyCount(idx: nodeIndex) {
            guard name == getNodePropertyName(
                idx: nodeIndex,
                propIdx: propIndex
            ) else {
                continue
            }
            return propIndex
        }
        return nil
    }

    func isUniqueNameInOwner(at nodeIndex: Int32) -> Bool {
        guard let value = getNodeProperty(.uniqueNameInOwner, at: nodeIndex) else {
            return false
        }
        return Bool(value) ?? false
    }

    /// Returns an array of the names of the first animation library found in the `libraries` property.
    /// If there is no libraries property it will return an empty array.
    func animationList(at nodeIndex: Int32) -> [String] {
        guard let libraries = getNodeProperty(.libraries, at: nodeIndex),
              let gdict = GDictionary(libraries),
              let library: AnimationLibrary = gdict.values().front().asObject()
        else {
            return []
        }

        return library.getAnimationList().map(\.description)
    }
}
