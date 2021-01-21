struct Ass: Package {
  func build(with builder: Builder) throws {
    try builder.autoreconf()
    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag,
      "--disable-fontconfig"
    )

    try builder.make()
    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://github.com/libass/libass/releases/download/0.15.0/libass-0.15.0.tar.xz")!, filename: nil)
  }

  var dependencies: [Package] {
    [Freetype.new(), Harfbuzz.new(), Fribidi.new()]
  }
}
