// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SceneGen",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "scene-gen",
            targets: [
                "SceneGen",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.2.0"
        ),
        .package(
            url: "https://github.com/migueldeicaza/SwiftGodotKit",
            branch: "main"
        ),
        .package(
            url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "SceneGen",

            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftGodotKit", package: "SwiftGodotKit"),
            ]
        ),
    ]
)
