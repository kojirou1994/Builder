import BuildSystem

struct Webp: Package {
  var version: PackageVersion {
    .stable("1.1.0")
  }

  func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
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

    try env.make()
    
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.1.0.tar.gz")
  }

//  var dependencies: [Package] {
//    [Mozjpeg.new(), Png.new()]
//  }
}
