import BuildSystem

public struct Mpfr: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "4.1.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/mpfr/mpfr-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Gmp.self)
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    if env.strictMode {
      try env.make("check")
    }
    try env.make("install")
  }

}
