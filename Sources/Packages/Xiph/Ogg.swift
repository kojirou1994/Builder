import BuildSystem

public struct Ogg: Package {

  public init() {}
  /*
   1.3.4 always fail?
   https://gitlab.xiph.org/xiph/ogg/-/issues/2298
   */
  public var defaultVersion: PackageVersion {
    "1.3.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/xiph/ogg.git")
    case .stable(let version):
      source = .tarball(url: "https://downloads.xiph.org/releases/ogg/libogg-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      products: [
        .library(name: "libogg", headers: ["ogg"]),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.fixAutotoolsForDarwin()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    if env.canRunTests {
      try env.make("check")
    }
    try env.make(parallelJobs: 1, "install")
  }

}
