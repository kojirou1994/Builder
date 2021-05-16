import BuildSystem

public struct Dvdcss: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.4.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "http://download.videolan.org/pub/videolan/libdvdcss/\(version.toString())/libdvdcss-\(version.toString()).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      products: [.library(name: "libdvdcss", headers: ["dvdcss"])]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    try context.make("install")
  }

}
