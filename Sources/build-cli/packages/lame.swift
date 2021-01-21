struct Lame: Package {
  func build(with builder: Builder) throws {

    try replace(contentIn: "include/libmp3lame.sym", matching: "lame_init_old\n", with: "")

    try builder.autoreconf()

    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.buildStatic.configureFlag("static"),
      builder.settings.library.buildShared.configureFlag("shared"),
      true.configureFlag("nasm")
    )

    try builder.make("install")
  }

  var version: BuildVersion {
    /*
     1.3.4 always fail?
     https://gitlab.xiph.org/xiph/ogg/-/issues/2298
     */
    .ball(url: URL(string: "https://netcologne.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz")!, filename: nil)
  }

}
