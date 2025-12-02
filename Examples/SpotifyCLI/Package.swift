// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SpotifyCLI",
    platforms: [
        .macOS(.v15),
        .iOS(.v17),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(name: "SpotifyKit", path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "SpotifyCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "SpotifyKit",
            ]
        )
    ]
)
