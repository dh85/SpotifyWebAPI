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
            name: "SpotifyWebAPI",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .testTarget(
            name: "SpotifyWebAPITests",
            dependencies: [
                "SpotifyWebAPI",
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            path: "Tests",
            // Sources will only look in these folders
            sources: [
                "SpotifyWebAPITests",
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
