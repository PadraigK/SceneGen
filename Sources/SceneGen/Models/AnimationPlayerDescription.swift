//
//  AnimationPlayerDescription.swift
//
//
//  Created by Padraig O Cinneide on 2023-10-12.
//

import Foundation

/// This is an intermediate representation of an animation player's library or animations
/// and is used during code rendering.
struct AnimationPlayerDescription {
    let playerPath: String
    let playerSwiftName: String
    let animationNames: [String]
}
