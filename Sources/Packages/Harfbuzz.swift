import BuildSystem

public struct Harfbuzz: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.8.0"
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
      dependencies: PackageDependencies(
        packages: [
          .buildTool(Cmake.self),
          .buildTool(Ninja.self),
          .buildTool(PkgConfig.self),
          .runTime(Freetype.self),
          .runTime(Icu4c.self),
        ]
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename) { _ in
      try env.meson(
        "--default-library=\(env.libraryType.mesonFlag)",
        env.libraryType == .static ? mesonDefineFlag(false, "b_lundef") : nil,
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

      try env.launch("ninja")
      try env.launch("ninja", "install")
    }
  }
}
