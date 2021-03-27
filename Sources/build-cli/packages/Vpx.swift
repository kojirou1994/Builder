import BuildSystem

struct Vpx: Package {
  var defaultVersion: PackageVersion {
    .stable("1.10.0")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/webmproject/libvpx/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/webmproject/libvpx/archive/refs/tags/v\(version.toString()).tar.gz")
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

}
