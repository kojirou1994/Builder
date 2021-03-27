import BuildSystem

struct Ninja: Package {
  var defaultVersion: PackageVersion {
    .stable("1.10.2")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/ninja-build/ninja/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/ninja-build/ninja/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build") { _ in
      try env.cmake(
        toolType: .make, 
        ".."
        /* -DBUILD_TESTING */
      )

      try env.make()

      try env.make("install")
    }
  }

}
