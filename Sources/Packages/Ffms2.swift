import BuildSystem

public struct Ffms2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.40"
  }

  @Flag(help: "Need all static linked")
  private var pack: Bool = false

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
        pack ?
          .custom(package: Ffmpeg.minimalDecoder, requiredTime: .buildTime, libraryType: .static)
        : .runTime(Ffmpeg.minimalDecoder),
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
