import BuildSystem

public struct File: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "5.43"
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

  public func build(with context: BuildContext) throws {
    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "fsect-man5")
    )

    try context.make()

    try context.make("install")
  }

}
