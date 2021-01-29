// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Builder",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "BuildSystem", type: .dynamic, targets: ["BuildSystem"]),
    .executable(name: "build-cli", targets: ["build-cli"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/URLFileManager.git", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.8.0"),
    .package(url: "https://github.com/kojirou1994/Executable.git", from: "0.4.0"),
  ],
  targets: [
    .target(
      name: "BuildSystem",
      dependencies: [
        .product(name: "ExecutableLauncher", package: "Executable"),
        "URLFileManager",
        .product(name: "Logging", package: "swift-log"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "KwiftUtility", package: "Kwift")
      ]),
    .target(
      name: "build-cli",
      dependencies: [
        "BuildSystem"
      ]),
    .target(
      name: "generate-code",
      dependencies: [
        "URLFileManager",
      ]),
    .testTarget(
      name: "BuilderSystemTests",
      dependencies: ["BuildSystem"]),
  ]
)
