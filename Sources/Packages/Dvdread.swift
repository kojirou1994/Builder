import BuildSystem

public struct Dvdread: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "6.1.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://download.videolan.org/pub/videolan/libdvdread/\(version.toString())/libdvdread-\(version.toString()).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: .init(packages: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Dvdcss.self),
      ]),
      products: [.library(name: "libogg", headers: ["ogg"])]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureWithFlag(true, "libdvdcss")
    )

    try env.make()
    try env.make("install")
  }

}