import BuildSystem

public struct Flac: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      var versionString = version.toString(includeZeroPatch: false)
      if version < "1.0.3" {
        versionString += "-src"
      }
      let suffix: String
      if version < "1.3.0" {
        suffix = "gz"
      } else {
        suffix = "xz"
      }
      source = .tarball(url: "https://downloads.xiph.org/releases/flac/flac-\(versionString).tar.\(suffix)")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: [
          .buildTool(Autoconf.self),
          .buildTool(Automake.self),
          .buildTool(Libtool.self),
          .buildTool(PkgConfig.self),
          ogg ? .runTime(Ogg.self) : nil
        ]),
      products: [
        .library(name: "libFLAC", headers: ["FLAC"])
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    /*
     add -mfpu=neon to cflags and ldflags on arm
     */
    let useASM = env.target.arch == .x86_64
    try env.autogen()
    
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      ogg ? "--with-ogg=\(env.dependencyMap[Ogg.self].root.path)" : configureEnableFlag(false, "ogg"),
      configureEnableFlag(cpplibs, "cpplibs"),
      configureEnableFlag(false, "64-bit-words"),
      configureEnableFlag(false, "examples"),
      configureEnableFlag(useASM, "asm-optimizations", defaultEnabled: true)
    )

    try env.make()
    try env.make("install")
  }

  @Flag
  var cpplibs: Bool = false

  @Flag
  var ogg: Bool = false
  /*
   --enable-64-bit-words
   */

  public var tag: String {
    var str = ""
    if cpplibs {
      str.append("CPPLIBS")
    }
    if ogg {
      str.append("OGG")
    }
    return str
  }
}
