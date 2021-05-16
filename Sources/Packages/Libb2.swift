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

  public func build(with context: BuildContext) throws {
    try context.autogen()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(TargetArch.native.canLaunch(arch: context.order.target.arch) && context.order.target.system == .native, "native"),
      configureEnableFlag(false, "fat")
    )

    let forceEnv = "CFLAGS=\(context.environment[.cflags])"
    try context.make(forceEnv)
    if context.canRunTests {
      try context.make("check", forceEnv)
    }
    try context.make("install", forceEnv)
  }
}
