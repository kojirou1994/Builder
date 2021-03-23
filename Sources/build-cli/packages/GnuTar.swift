import BuildSystem

struct GnuTar: Package {
  var version: PackageVersion {
    .stable("1.34")
  }
  var source: PackageSource {
    packageSource(for: version)!
  }

  var products: [BuildProduct] {
    [
      .bin("tar"),
    ]
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    switch version {
    case .stable(let v):
      return .tarball(url: "https://ftp.gnu.org/gnu/tar/tar-\(v).tar.gz")
    default:
      return nil
    }
  }

  func build(with env: BuildEnvironment) throws {
    try env.configure()
    try env.make()
    try env.make("install")
  }

}
