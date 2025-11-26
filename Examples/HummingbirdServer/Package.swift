// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "HummingbirdServer",
    platforms: [
        .macOS(.v15),
        .iOS(.v17),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(name: "SpotifyWebAPI", path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "HummingbirdServer",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                "SpotifyWebAPI",
            ]
        )
    ]
)
