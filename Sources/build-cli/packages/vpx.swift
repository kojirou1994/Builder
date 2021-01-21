struct Vpx: Package {
  func build(with builder: Builder) throws {

    try builder.withChangingDirectory("mac_build", block: { _ in
      try builder.launch(
        path: "../configure",
        "--prefix=\(builder.settings.prefix)",
        false.configureFlag(CommonOptions.dependencyTracking),
        // shared won't compile, so always build static as default
        false.configureFlag("examples"),
        false.configureFlag("unit-tests"),
        true.configureFlag("pic"),
        true.configureFlag("vp9-highbitdepth")
      )

      try builder.make("install")
    })
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://github.com/webmproject/libvpx/archive/v1.9.0.tar.gz")!, filename: "libvpx-1.9.0.tar.gz")
  }

}
