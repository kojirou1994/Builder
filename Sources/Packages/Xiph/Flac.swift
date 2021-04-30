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
          .runTime(Ogg.self)
        ]),
      products: [
        .bin("flac"),
        .bin("metaflac"),
        .library(name: "libFLAC", headers: ["FLAC"])
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    switch env.order.target.arch {
    case .arm64, .arm64e, .armv7, .armv7s:
      env.environment.append("-mfpu=neon", for: .cflags, .ldflags)
    default: break
    }

    let useASM = env.order.target.arch == .x86_64
    try env.autogen()
    
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
//      "--with-ogg=\(env.dependencyMap[Ogg.self].root.path)",
      configureEnableFlag(cpplibs, "cpplibs"),
      configureEnableFlag(true, "64-bit-words"),
      configureEnableFlag(false, "examples"),
      configureEnableFlag(false, "oggtest"),
      configureEnableFlag(useASM, "asm-optimizations", defaultEnabled: true)
    )

    try env.make()
    try env.make("install")
  }

  @Flag(inversion: .prefixedEnableDisable)
  var cpplibs: Bool = false

  public var tag: String {
    [
      cpplibs ? "CPPLIBS" : ""
    ].joined(separator: "_")
  }
}
