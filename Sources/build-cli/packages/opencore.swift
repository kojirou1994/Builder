struct Opencore: Package {
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
    .ball(url: URL(string: "https://deac-riga.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.5.tar.gz")!, filename: nil)
  }

}
