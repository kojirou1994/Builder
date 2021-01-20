struct Aribb24: Package {
  func build(with builder: Builder) throws {
    try builder.launch(path: "bootstrap")
    try builder.configure(
      builder.settings.library.staticConfigureFlag,
      builder.settings.library.sharedConfigureFlag
    )

    try builder.make()
    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://github.com/nkoriyama/aribb24/archive/v1.0.3.tar.gz")!, filename: "aribb24-1.0.3.tar.gz")
  }

  var dependencies: [Package] {
    [Png.new()]
  }
}
