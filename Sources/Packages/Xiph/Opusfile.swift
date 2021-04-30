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
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opusfile-\(version.toString(includeZeroPatch: false)).tar.gz")
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
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      configureEnableFlag(false, "doc"),
      configureEnableFlag(false, "examples")
    )

    try env.make()
    try env.make("install")
  }

}
