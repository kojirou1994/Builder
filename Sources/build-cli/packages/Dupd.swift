import BuildSystem

struct Dupd: Package {
  var defaultVersion: PackageVersion {
    .stable("1.7.0")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/jvirkki/dupd/archive/refs/tags/\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {

    try env.make("install", "INSTALL_PREFIX=\(env.prefix.root.path)")
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .brew(["openssl@1.1"])
  }
}
