import BuildSystem

struct Vpx: Package {
  var version: PackageVersion {
    .stable("1.9.0")
  }

  func build(with env: BuildEnvironment) throws {

    try env.changingDirectory("mac_build", block: { _ in
      try env.launch(
        path: "../configure",
        "--prefix=\(env.prefix.root.path)",
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        // shared won't compile, so always build static as default
        configureEnableFlag(false, "examples"),
        configureEnableFlag(false, "unit-tests"),
        configureEnableFlag(true, "pic"),
        configureEnableFlag(true, "vp9-highbitdepth")
      )

      try env.make("install")
    })
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/webmproject/libvpx/archive/v1.9.0.tar.gz", filename: "libvpx-1.9.0.tar.gz")
  }

}
