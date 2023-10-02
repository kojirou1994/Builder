import BuildSystem

public struct CargoUpdate: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "13.1.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://github.com/nabijaczleweli/cargo-update/archive/refs/tags/v\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(PkgConfig.self),
        .runTime(Openssl.self),
        .runTime(Libssh2.self),
        .runTime(Libgit2.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    context.environment["LIBSSH2_SYS_USE_PKG_CONFIG"] = "1"
    try context.launch("cargo", "install", "cargo-update")
  }
}
