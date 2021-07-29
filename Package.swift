// swift-tools-version:5.4

import PackageDescription

let package = Package(
  name: "Builder",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "BuildSystem", type: .dynamic, targets: ["BuildSystem"]),
    .library(name: "Packages", targets: ["Packages"]),
    .executable(name: "build-cli", targets: ["build-cli"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/URLFileManager.git", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.8.0"),
    .package(url: "https://github.com/kojirou1994/Executable.git", from: "0.4.0"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0"),
    .package(url: "https://github.com/vapor/console-kit.git", from: "4.2.0"),
  ],
  targets: [
    .target(
      name: "XcodeExecutable",
      dependencies: [
        .product(name: "ExecutableDescription", package: "Executable"),
      ]),
    .target(
      name: "BuildSystem",
      dependencies: [
        .target(name: "XcodeExecutable"),
        .product(name: "URLFileManager", package: "URLFileManager"),
        .product(name: "ExecutableLauncher", package: "Executable"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "KwiftUtility", package: "Kwift"),
        .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])),
      ]),
    .target(
      name: "Packages",
      dependencies: [
        .target(name: "BuildSystem"),
      ]),
    .target(
      name: "PackagesInfo",
      dependencies: [
        .target(name: "Packages"),
      ]),
    .executableTarget(
      name: "build-cli",
      dependencies: [
        .target(name: "PackagesInfo"),
        .product(name: "ConsoleKit", package: "console-kit")
      ]),
    .executableTarget(
      name: "spm",
      dependencies: [
        .target(name: "BuildSystem"),
      ]),
    .executableTarget(
      name: "generate-code",
      dependencies: [
        .product(name: "URLFileManager", package: "URLFileManager"),
        .product(name: "Precondition", package: "Kwift"),
      ]),
    .testTarget(
      name: "BuilderSystemTests",
      dependencies: [
        .target(name: "BuildSystem"),
        .target(name: "PackagesInfo"),
      ]),
  ]
)
