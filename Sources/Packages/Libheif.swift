import BuildSystem

public struct Libheif: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.12"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/strukturag/libheif.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/strukturag/libheif/releases/download/v\(version)/libheif-\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(PkgConfig.self),
        .runTime(x265.self),
        .runTime(Libde265.self),
        .runTime(Mozjpeg.self),
        .runTime(Aom.self),
        .runTime(Rav1e.self),
        .runTime(Dav1d.self),
        .runTime(Png.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    try context.make("install")
  }

}
