import BuildSystem

public struct Ass: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.17.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/libass/libass/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/libass/libass/archive/refs/tags/\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Freetype.self),
        .runTime(Harfbuzz.self),
        .runTime(Fribidi.self),
        .buildTool(Nasm.self),
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.autoreconf()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "fontconfig"),
      configureEnableFlag(context.order.system != .linuxGNU, "require-system-font-provider", defaultEnabled: true),
      nil
      //      "HARFBUZZ_CFLAGS=-I\(context.dependencyMap[Harfbuzz.self].include.path)",
      //      "HARFBUZZ_LIBS=-L\(context.dependencyMap[Harfbuzz.self].lib.path) -lharfbuzz"
    )

    try context.make()
    try context.make("install")
  }

}
