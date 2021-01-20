struct Png: Package {
  func build(with builder: Builder) throws {
    
    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag
    )

    try builder.make()

//    try builder.make("test")
    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz")!, filename: nil)
  }
}
