struct Harfbuzz: Package {
  func build(with builder: Builder) throws {
    try builder.withChangingDirectory("build", block: { _ in
      try builder.meson(
        "--default-library=\(builder.settings.library.mesonFlag)",
        builder.settings.library == .statik ? "-Db_lundef=false" : nil,
        "-Dcairo=disabled",
        "-Dcoretext=enabled",
        "-Dfreetype=enabled",
        "-Dglib=disabled",
        "-Dgobject=disabled",
        "-Dgraphite=disabled",
        "-Dicu=enabled",
        "-Dintrospection=disabled"
      )

      try builder.launch("ninja")
      try builder.launch("ninja", "install")
    })
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://github.com/harfbuzz/harfbuzz/archive/2.7.4.tar.gz")!, filename: "harfbuzz-2.7.4.tar.gz")
  }

  var dependencies: [Package] {
    [Freetype.new(), Icu4c.new()]
  }
}
