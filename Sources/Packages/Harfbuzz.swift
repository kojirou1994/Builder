import BuildSystem

struct Harfbuzz: Package {
  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build", block: { _ in
      try env.meson(
        "--default-library=\(env.libraryType.mesonFlag)",
        env.libraryType == .statik ? "-Db_lundef=false" : nil,
        "-Dcairo=disabled",
        "-Dcoretext=enabled",
        "-Dfreetype=enabled",
        "-Dglib=disabled",
        "-Dgobject=disabled",
        "-Dgraphite=disabled",
        "-Dicu=enabled",
        "-Dintrospection=disabled"
      )

      try env.launch("ninja")
      try env.launch("ninja", "install")
    })
  }

  var defaultVersion: PackageVersion {
    .stable("2.7.4")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/harfbuzz/harfbuzz/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/harfbuzz/harfbuzz/archive/refs/tags/\(version.toString()).tar.gz")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Freetype.self), .init(Icu4c.self))
  }
}
