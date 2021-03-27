import BuildSystem

struct Fmtconv: Package {
  var defaultVersion: PackageVersion {
    .stable("22")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/EleonoreMizo/fmtconv/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/EleonoreMizo/fmtconv/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build/unix", block: { _ in
      try env.autogen()

      try env.configure(
        
      )

      try env.make()
      try env.make("install")
    })
  }
}
