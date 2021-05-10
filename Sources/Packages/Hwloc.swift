import BuildSystem

public struct Hwloc: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.4.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://download.open-mpi.org/release/hwloc/v\(version.major).\(version.minor)/hwloc-\(version.toString()).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(PkgConfig.self),
        .runTime(Xml2.self),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
//    try env.autoreconf()

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--disable-cairo",
      "--without-x"
    )

    try env.make()
    try env.make("install")
  }

}
