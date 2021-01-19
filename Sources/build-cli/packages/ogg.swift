struct Ogg: Package {
  func build(with builder: Builder) throws {
    try builder.autoreconf()

    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.buildStatic.configureFlag("static"),
      builder.settings.library.buildShared.configureFlag("shared")
    )

    try builder.make("install")
  }

  var version: BuildVersion {
    /*
     1.3.4 always fail?
     https://gitlab.xiph.org/xiph/ogg/-/issues/2298
     */
    .ball(url: URL(string: "https://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.gz")!, filename: nil)
  }

}
