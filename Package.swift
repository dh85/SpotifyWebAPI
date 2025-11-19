// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SpotifyWebAPI",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "SpotifyWebAPI",
            targets: ["SpotifyWebAPI"]
        )
    ],
    targets: [
        .target(
            name: "SpotifyWebAPI"
        ),
        .testTarget(
            name: "SpotifyWebAPITests",
            dependencies: ["SpotifyWebAPI"],
            resources: [.process("Mocks")]
        ),
    ]
)
