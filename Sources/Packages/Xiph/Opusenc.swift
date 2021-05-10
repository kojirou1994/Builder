import BuildSystem

public struct Opusenc: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.2.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/xiph/libopusenc.git")
    case .stable(let version):
      source = .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/libopusenc-\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Opus.self),
      ],
      products: [
        .library(name: "opusenc", headers: ["opus/opusenc.h"]),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.fixAutotoolsForDarwin()
    
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "doc"),
      configureEnableFlag(false, "examples")
    )
    
    try env.make()
    if env.canRunTests {
      try env.make("check")
    }
    try env.make("install")
  }

}
