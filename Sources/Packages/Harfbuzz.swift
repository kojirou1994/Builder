import BuildSystem

public struct Harfbuzz: Package {

  public init() {}

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename, block: { _ in
//      try env.meson(
//        "--default-library=\(env.libraryType.mesonFlag)",
//        env.libraryType == .statik ? "-Db_lundef=false" : nil,
//        mesonFeatureFlag(false, "cairo"),
//        mesonFeatureFlag(true, "coretext"),
//        mesonFeatureFlag(true, "freetype"),
//        mesonFeatureFlag(false, "glib"),
//        mesonFeatureFlag(false, "gobject"),
//        mesonFeatureFlag(false, "graphite"),
//        mesonFeatureFlag(true, "icu"),
//        mesonFeatureFlag(false, "introspection"),
//        ".."
//      )

      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(env.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(true, "HB_HAVE_CORETEXT"),
        cmakeOnFlag(true, "HB_HAVE_FREETYPE"),
        cmakeOnFlag(false, "HB_HAVE_GLIB"),
        cmakeOnFlag(false, "HB_HAVE_GOBJECT"),
        cmakeOnFlag(false, "HB_HAVE_GRAPHITE2"),
        cmakeOnFlag(true, "HB_HAVE_ICU"),
        cmakeOnFlag(false, "HB_HAVE_INTROSPECTION"),
        nil
        )
      try env.launch("ninja")
      try env.launch("ninja", "install")
    })
  }

  public var defaultVersion: PackageVersion {
    .stable("2.7.4")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/harfbuzz/harfbuzz/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/harfbuzz/harfbuzz/archive/refs/tags/\(version.toString()).tar.gz")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Freetype.self), .init(Icu4c.self))
  }
}
