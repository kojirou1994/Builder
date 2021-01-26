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

  var source: PackageSource {
    .tarball(url: "https://github.com/harfbuzz/harfbuzz/archive/2.7.4.tar.gz", filename: "harfbuzz-2.7.4.tar.gz")
  }

  var dependencies: PackageDependency {
    .packages(Freetype.defaultPackage(), Icu4c.defaultPackage())
  }
}
