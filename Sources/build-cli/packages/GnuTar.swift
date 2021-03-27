import BuildSystem

struct GnuTar: Package {
  var defaultVersion: PackageVersion {
    .stable("1.34")
  }
  
  var products: [BuildProduct] {
    [
      .bin("tar"),
    ]
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://ftp.gnu.org/gnu/tar/tar-latest.tar.xz")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ftp.gnu.org/gnu/tar/tar-\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure()
    try env.make()
    try env.make("install")
  }

}
