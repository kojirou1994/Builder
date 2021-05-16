import BuildSystem

public struct Png: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.6.37"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://downloads.sourceforge.net/project/libpng/libpng16/\(version)/libpng-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [.runTime(Zlib.self)]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()

    if context.canRunTests {
      try context.make("test")
    }

    try context.make("install")
  }

}
