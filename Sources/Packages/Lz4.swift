import BuildSystem

public struct Lz4: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.10"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/lz4/lz4/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ],
      products: [
        .bin("lz4"), .bin("lz4c"), .bin("lz4cat"), .bin("unlz4"),
        .library(name: "lz4", headers: ["lz4.h", "lz4frame.h", "lz4hc.h"]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory("build/cmake") { _ in
      try context.inRandomDirectory { _ in
        try context.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(context.libraryType.buildStatic, "BUILD_STATIC_LIBS"),
          cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
          cmakeOnFlag(false, "LZ4_BUILD_LEGACY_LZ4C"),
          cmakeOnFlag(true, "LZ4_BUILD_CLI"),
          cmakeOnFlag(true, "CMAKE_MACOSX_RPATH")
        )

        try context.make(toolType: .ninja)
        try context.make(toolType: .ninja, "install")
      }
    }
    // TODO: link lz4c to lz4
  }
}
