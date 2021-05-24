import BuildSystem

public struct Opusfile: Package {

  @Flag(inversion: .prefixedEnableDisable)
  var http = true

  public init() {}

  public var tag: String {
    [
      http ? "": "NO_HTTP"
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }

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

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Ogg.self),
        .runTime(Opus.self),
        http ? .runTime(Openssl.self) : nil,
      ],
      products: [
        .library(name: "opusfile", libname: "opusfile", headerRoot: "opus", headers: ["opusfile.h"], shimedHeaders: []),
        .library(name: "opusurl", libname: "opusurl", headerRoot: "", headers: nil, shimedHeaders: [])
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      configureEnableFlag(true, "doc"),
      configureEnableFlag(http, "http"),
      configureEnableFlag(false, "examples")
    )

    try context.make()
    try context.make("install")
  }

}
