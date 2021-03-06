import BuildSystem

public struct Ffms2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.40"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/FFMS/ffms2/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/FFMS/ffms2/archive/refs/tags/\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Ffmpeg.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autogen()
    try context.configure(
      context.libraryType.sharedConfigureFlag,
      context.libraryType.staticConfigureFlag
    )

    try context.make("install")
  }

}
