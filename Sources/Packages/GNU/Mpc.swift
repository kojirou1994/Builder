import BuildSystem

public struct Mpc: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.2.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/mpc/mpc-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Mpfr.self)
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
