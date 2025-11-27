// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SpotifyKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
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
            url: "https://github.com/apple/swift-crypto.git",
            from: "3.0.0"
        ),
        .package(
            url: "https://github.com/hummingbird-project/hummingbird.git",
            from: "2.0.0"
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
                "SpotifyKit",
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            path: "Tests",
            // Sources will only look in these folders
            sources: [
                "SpotifyKitTests",
                "Support",
            ],
            // Resources now points to the sibling folder "Mocks"
            // This path is relative to the target path "Tests"
            resources: [
                .process("Mocks")
            ]
        ),
    ]
)
