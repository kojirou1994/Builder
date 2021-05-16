import BuildSystem

public struct Aribb24: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.0.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/nkoriyama/aribb24/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Png.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    try context.make("install")
  }

}
