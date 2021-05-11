import BuildSystem

public struct Lzfse: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.0.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/lzfse/lzfse.git")
    case .stable(let version):
      let versionString = version.toString(includeZeroPatch: false)
      source = .tarball(url: "https://github.com/lzfse/lzfse/archive/refs/tags/lzfse-\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ],
      products: [
        .bin("lzfse"),
        .library(name: "lzfse", headers: ["lzfse.h"]),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.inRandomDirectory { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(env.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(!env.strictMode, "LZFSE_DISABLE_TESTS"),
        cmakeOnFlag(true, "CMAKE_MACOSX_RPATH"),
        cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR")
      )

      try env.make(toolType: .ninja)
      if env.canRunTests {
        try env.make(toolType: .ninja, "test")
      }
      try env.make(toolType: .ninja, "install")
    }
  }
}
