import BuildSystem

struct Ass: Package {
  func build(with builder: Builder) throws {
    try builder.autoreconf()
    try builder.configure(
      configureFlag(false, CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag,
      configureFlag(false, "fontconfig")
    )

    try builder.make()
    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/libass/libass/releases/download/0.15.0/libass-0.15.0.tar.xz")
  }

  var dependencies: [Package] {
    [Freetype.defaultPackage(), Harfbuzz.defaultPackage(), Fribidi.defaultPackage()]
  }
}
