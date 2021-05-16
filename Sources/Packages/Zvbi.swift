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

  public func build(with context: BuildContext) throws {

    try context.autoreconf()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureWithFlag(false, "libintl-prefix"),
      configureWithFlag(false, "x")
    )

    if !context.canRunTests {
      // test cannot build on mobile system
      try """
        all:

        install:

        """.write(to: URL(fileURLWithPath: "test/Makefile"), atomically: true, encoding: .utf8)
    }

    try context.make()
    if context.canRunTests {
      try context.make("check")
    }
    try context.make("install")
  }

}
