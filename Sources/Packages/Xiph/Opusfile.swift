import BuildSystem

public struct Opusfile: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.12"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/xiph/opusfile.git")
    case .stable(let version):
      source = .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opusfile-\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    var libraryType: PackageLibraryBuildType = .all

    if order.target.system == .macCatalyst {
      libraryType = .static // auto tools don't support catalyst shared lib
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Ogg.self),
        .runTime(Opus.self),
        .runTime(Openssl.self),
      ],
      products: [
        .library(name: "opusfile", headers: ["opus"]),
        .library(name: "opusurl", headers: ["opus"]),
      ],
      supportedLibraryType: libraryType
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      configureEnableFlag(true, "doc"),
      configureEnableFlag(false, "examples")
    )

    try context.make()
    try context.make("install")
  }

}
