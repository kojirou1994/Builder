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

  public func build(with context: BuildContext) throws {

    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    if context.strictMode {
      try context.make("check")
    }
    try context.make("install")
  }

}
