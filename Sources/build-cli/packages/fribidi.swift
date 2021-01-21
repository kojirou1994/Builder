struct Fribidi: Package {
  func build(with builder: Builder) throws {
    try builder.autoreconf()

    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag
    )

    try builder.make()
    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://github.com/fribidi/fribidi/releases/download/v1.0.10/fribidi-1.0.10.tar.xz")!, filename: nil)
  }
}
