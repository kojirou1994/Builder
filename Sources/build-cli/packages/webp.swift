import BuildSystem

struct Webp: Package {
  var version: PackageVersion {
    .stable("1.1.0")
  }

  func build(with builder: Builder) throws {
    try builder.autoreconf()

    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag,
      "--disable-gl",
      "--disable-sdl",
      "--disable-png",
      "--disable-jpeg",
      "--disable-tiff",
      "--disable-gif",
      "--disable-wic",
      "--enable-libwebpmux",
      "--enable-libwebpdecoder",
      "--enable-libwebpdemux",
      "--enable-libwebpextras"
    )

    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.1.0.tar.gz")
  }

//  var dependencies: [Package] {
//    [Mozjpeg.new(), Png.new()]
//  }
}
