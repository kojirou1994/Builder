struct Vorbis: Package {
  func build(with builder: Builder) throws {

    try builder.autoreconf()

    try builder.configure(
      false.configureFlag(CommonOptions.dependencyTracking),
      builder.settings.library.buildStatic.configureFlag("static"),
      builder.settings.library.buildShared.configureFlag("shared"),
      examples.configureFlag("examples"),
      docs.configureFlag("docs"),
      false.configureFlag("oggtest"),
      "--with-ogg-libraries=\(builder.productsDirectoryURL.appendingPathComponent("lib").path)",
      "--with-ogg-includes=\(builder.productsDirectoryURL.appendingPathComponent("include").path)"
    )
    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz")!, filename: nil)
  }

  var dependencies: [Package] {
    [Ogg.new()]
  }

  @Flag(inversion: .prefixedEnableDisable, help: "build the examples.")
  var examples: Bool = false

  @Flag(inversion: .prefixedEnableDisable, help: "build the documentation.")
  var docs: Bool = false

}
