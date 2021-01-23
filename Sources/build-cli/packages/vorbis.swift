import BuildSystem

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

  var source: PackageSource {
    .tarball(url: "https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz")
  }

  var dependencies: [Package] {
    [Ogg.defaultPackage()]
  }

  @Flag(inversion: .prefixedEnableDisable, help: "build the examples.")
  var examples: Bool = false

  @Flag(inversion: .prefixedEnableDisable, help: "build the documentation.")
  var docs: Bool = false

}
