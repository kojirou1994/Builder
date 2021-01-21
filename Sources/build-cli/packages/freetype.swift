struct Freetype: Package {
  func build(with builder: Builder) throws {

    try builder.launch(path: "autogen.sh")

    try builder.configure(
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag,
      "--enable-freetype-config",
      "--without-harfbuzz",
      "--without-brotli"
    )

    try builder.make()
    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://downloads.sourceforge.net/project/freetype/freetype2/2.10.4/freetype-2.10.4.tar.xz")!, filename: nil)
  }

  var dependencies: [Package] {
    [Png.new()]
  }
}
