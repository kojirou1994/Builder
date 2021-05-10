import BuildSystem

public struct Lzo: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.10.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroPatch: false)
      source = .tarball(url: "https://www.oberhumer.com/opensource/lzo/download/lzo-\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
      ],
      products: [
        .library(name: "lzo2", headers: ["lzo"]),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.inRandomDirectory { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(env.strictMode, "BUILD_TESTING"),
        cmakeOnFlag(env.libraryType.buildShared, "ENABLE_SHARED"),
        cmakeOnFlag(env.libraryType.buildStatic, "ENABLE_STATIC"),
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
