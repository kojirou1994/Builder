import BuildSystem

public struct Gmp: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "6.2.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/gmp/gmp-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(M4.self)
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.configure(
      configureEnableFlag(true, "cxx"),
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
