// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SpotifyKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "SpotifyKit",
            targets: ["SpotifyKit"]
        ),
        .library(
            name: "SpotifyExampleContent",
            targets: ["SpotifyExampleContent"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.3.0"
        ),
        .package(
            url: "https://github.com/apple/swift-crypto.git",
            from: "3.0.0"
        ),
    ],
    targets: [
        .target(
            name: "SpotifyKit",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .target(
            name: "SpotifyExampleContent",
            dependencies: ["SpotifyKit"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SpotifyKitTests",
            dependencies: [
                "SpotifyKit"
            ],
            path: "Tests",
            exclude: [
                "Support/SpotifyMockAPIServer.swift",
                "SpotifyKitTests/Integration",
            ],
            sources: [
                "SpotifyKitTests",
                "Support",
            ],
            resources: [
                .process("Mocks")
            ]
        ),
    ]
)
