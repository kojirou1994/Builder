import BuildSystem

struct Ass: Package {
  func build(with env: BuildEnvironment) throws {
    try env.autoreconf()
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "fontconfig")
    )

    try env.make()
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/libass/libass/releases/download/0.15.0/libass-0.15.0.tar.xz")
  }

  var dependencies: PackageDependency {
    .packages(Freetype.defaultPackage(), Harfbuzz.defaultPackage(), Fribidi.defaultPackage())
  }
}
