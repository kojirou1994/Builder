import BuildSystem

public struct Xml2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.9.10"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "http://xmlsoft.org/sources/libxml2-\(version.toString()).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--without-python",
      "--without-lzma"
    )

    try env.make()

    try env.make("install")
  }
}
