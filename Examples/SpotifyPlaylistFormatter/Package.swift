// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "SpotifyPlaylistFormatter",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(
      name: "SpotifyPlaylistFormatter",
      targets: ["SpotifyPlaylistFormatter"]
    )
  ],
  dependencies: [
    .package(name: "SpotifyKit", path: "../../"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
  ],
  targets: [
    .executableTarget(
      name: "SpotifyPlaylistFormatter",
      dependencies: [
        .product(name: "SpotifyKit", package: "SpotifyKit"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      exclude: ["README.md"]
    ),
    .testTarget(
      name: "SpotifyPlaylistFormatterTests",
      dependencies: [
        "SpotifyPlaylistFormatter",
        .product(name: "SpotifyKit", package: "SpotifyKit")
      ]
    )
  ]
)
