import BuildSystem

public struct Flac: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    var dependencies: [PackageDependency]

    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/xiph/flac.git")
      dependencies = [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ]
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
      dependencies = [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
      ]
    }

    if ogg {
      dependencies.append(.runTime(Ogg.self))
    }

    return .init(
      source: source,
      dependencies: dependencies,
      products: [
        .bin("flac"),
        .bin("metaflac"),
        .library(name: "FLAC", headers: ["FLAC"]),
        .library(name: "FLAC++", headers: ["FLAC++"]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    let useASM = context.order.target.arch == .x86_64
    try context.autogen()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(cpplibs, "cpplibs"),
      configureEnableFlag(true, "64-bit-words"),
      configureEnableFlag(false, "examples"),
      configureEnableFlag(context.strictMode, "exhaustive-tests"), /* VERY long, took 30 minutes on my i7-4770hq machine */
      configureEnableFlag(useASM, "asm-optimizations", defaultEnabled: true)
    )

    try context.make()
    if context.canRunTests {
      try context.make("check")
    }
    try context.make("install")
  }

  @Flag(inversion: .prefixedNo)
  var cpplibs: Bool = false

  @Flag(inversion: .prefixedNo)
  var ogg: Bool = true

  public var tag: String {
    [
      cpplibs ? "CPPLIBS" : "",
      ogg ? "" : "NO-OGG",
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }
}
