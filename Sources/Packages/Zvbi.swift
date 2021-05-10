import BuildSystem

public struct Zvbi: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.2.35"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

//    switch order.target.system {
//    case .macOS, .linuxGNU:
//      break
//    default: throw PackageRecipeError.unsupportedTarget
//    }

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://nchc.dl.sourceforge.net/project/zapping/zvbi/\(versionString)/zvbi-\(versionString).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(Gettext.self),
        .runTime(Png.self),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.autoreconf()

    try env.fixAutotoolsForDarwin()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureWithFlag(false, "libintl-prefix"),
      configureWithFlag(false, "x")
    )

    if !env.canRunTests {
      // test cannot build on mobile system
      try """
        all:

        install:

        """.write(to: URL(fileURLWithPath: "test/Makefile"), atomically: true, encoding: .utf8)
    }

    try env.make()
    if env.canRunTests {
      try env.make("check")
    }
    try env.make("install")
  }

}
