import BuildSystem

public struct Opencore: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.1.5"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://deac-riga.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies:
        .init(otherPackages: [.brewAutoConf])
    )
  }
  
  public func build(with env: BuildEnvironment) throws {

    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

}
