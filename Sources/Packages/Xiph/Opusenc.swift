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

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.fixAutotoolsForDarwin()
    
    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "doc"),
      configureEnableFlag(false, "examples")
    )
    
    try context.make()
    if context.canRunTests {
      try context.make("check")
    }
    try context.make("install")
  }

}
