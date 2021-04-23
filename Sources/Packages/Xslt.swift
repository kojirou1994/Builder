import BuildSystem

public struct Xslt: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("1.1.34")
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "http://xmlsoft.org/sources/libxslt-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .packages(.init(Xml2.self), .init(Gcrypt.self))
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--without-python",
      nil
    )

    try env.make("install")
  }
}
