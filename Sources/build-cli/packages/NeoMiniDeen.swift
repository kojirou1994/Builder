import BuildSystem

struct NeoMiniDeen: Package {

  var defaultVersion: PackageVersion {
    .stable("10")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/MiniDeen/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/MiniDeen/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build", block: { _ in
      try env.cmake(toolType: .ninja, "..")

      try env.make(toolType: .ninja)
    })
  }
}
