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
