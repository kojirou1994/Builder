struct Opus: Package {
  func build(with builder: Builder) throws {
    try builder.configure(
      builder.settings.library.buildStatic.configureFlag("static"),
      builder.settings.library.buildShared.configureFlag("shared"),
      false.configureFlag("dependency-tracking"),
      false.configureFlag("doc")
    )
    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz")!, filename: nil)
  }
}
