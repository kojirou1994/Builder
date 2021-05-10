import BuildSystem

public struct Libb2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.98.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroPatch: false)
      source = .tarball(url: "https://github.com/BLAKE2/libb2/archive/refs/tags/v\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
      ],
      products: [
        .library(name: "b2", headers: ["blake2.h"])
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autogen()

    try env.fixAutotoolsForDarwin()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(TargetArch.native.canLaunch(arch: env.order.target.arch) && env.order.target.system == .native, "native"),
      configureEnableFlag(false, "fat")
    )

    let forceEnv = "CFLAGS=\(env.environment[.cflags])"
    try env.make(forceEnv)
    if env.canRunTests {
      try env.make("check", forceEnv)
    }
    try env.make("install", forceEnv)
  }
}
