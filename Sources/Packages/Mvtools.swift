import BuildSystem

struct Mvtools: Package {

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/dubhater/vapoursynth-mvtools/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/dubhater/vapoursynth-mvtools/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build", block: { _ in
      try env.meson("..")

      try env.launch("ninja")
      try env.launch("ninja", "install")
    })
  }
}
