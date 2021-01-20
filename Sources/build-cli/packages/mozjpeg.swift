struct Mozjpeg: Package {
  func build(with builder: Builder) throws {
    try builder.cmake(
      ".",
      builder.settings.library.staticCmakeFlag,
      builder.settings.library.sharedCmakeFlag
    )
    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://github.com/mozilla/mozjpeg/archive/v4.0.0.tar.gz")!, filename: "mozjpeg-4.0.0.tar.gz")
  }
}
