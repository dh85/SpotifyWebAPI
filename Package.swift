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
        )
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
            dependencies: ["SpotifyWebAPI"],
            path: "Tests",
            exclude: [
                "SpotifyWebAPITests/Mocks"
            ],
            sources: [
                "SpotifyWebAPITests",
                "Support"
            ],
            resources: [.process("SpotifyWebAPITests/Mocks")]
        ),
    ]
)
