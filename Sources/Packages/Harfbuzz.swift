import BuildSystem

public struct Harfbuzz: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.9.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/harfbuzz/harfbuzz/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/harfbuzz/harfbuzz/archive/refs/tags/\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Freetype.self),
        .runTime(Icu4c.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory(context.randomFilename) { _ in
      try context.meson(
        "--default-library=\(context.libraryType.mesonFlag)",
        context.libraryType == .static ? mesonDefineFlag(false, "b_lundef") : nil,
        mesonFeatureFlag(false, "cairo"),
        mesonFeatureFlag(true, "coretext"),
        mesonFeatureFlag(true, "freetype"),
        mesonFeatureFlag(false, "glib"),
        mesonFeatureFlag(false, "gobject"),
        mesonFeatureFlag(false, "graphite"),
        mesonFeatureFlag(true, "icu"),
        mesonFeatureFlag(false, "introspection"),
        ".."
      )

      try context.launch("ninja")
      try context.launch("ninja", "install")
    }
  }
}
