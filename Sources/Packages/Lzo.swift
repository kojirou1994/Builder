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

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.strictMode, "BUILD_TESTING"),
        cmakeOnFlag(context.libraryType.buildShared, "ENABLE_SHARED"),
        cmakeOnFlag(context.libraryType.buildStatic, "ENABLE_STATIC")
      )
      
      try context.make(toolType: .ninja)
      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")
    }
  }
}
