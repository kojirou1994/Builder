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
      dependencies: .init(packages: .runTime(Zlib.self))
    )
  }

  public func build(with env: BuildEnvironment) throws {
    
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()

//    try env.make("test")
    try env.make("install")
  }

}
