import BuildSystem

public struct File: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "5.40"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://astron.com/pub/file/file-\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Zlib.self)
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "fsect-man5")
    )

    try env.make()

    try env.make("install")
  }

}
