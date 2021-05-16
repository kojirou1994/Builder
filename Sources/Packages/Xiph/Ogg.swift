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

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    if context.canRunTests {
      try context.make("check")
    }
    try context.make(parallelJobs: 1, "install")
  }

}
