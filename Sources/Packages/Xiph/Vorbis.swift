import BuildSystem

public struct Vorbis: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.7"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Ogg.self),
      ],
      products: [
        .library(name: "vorbis", headers: ["vorbis/codec.h"]),
        .library(name: "vorbisenc", headers: ["vorbis/vorbisenc.h"]),
        .library(name: "vorbisfile", headers: ["vorbis/vorbisfile.h"]),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

//    if env.enableBitcode {
//      try replace(contentIn: "configure.ac", matching: "-force_cpusubtype_ALL", with: "")
//    }

    try env.autoreconf()

    try env.fixAutotoolsForDarwin()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(examples, "examples"),
      configureEnableFlag(docs, "docs"),
      configureEnableFlag(false, "oggtest")
    )

    try env.make()
    if env.canRunTests {
      try env.make("check")
    }
    try env.make("install")
  }

  @Flag(inversion: .prefixedEnableDisable, help: "build the examples.")
  var examples: Bool = false

  @Flag(inversion: .prefixedEnableDisable, help: "build the documentation.")
  var docs: Bool = false
  
  public var tag: String {
    [
      examples ? "examples" : "",
      docs ? "docs" : "",
    ].joined()
  }

}
