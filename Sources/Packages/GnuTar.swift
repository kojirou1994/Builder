import BuildSystem

public struct GnuTar: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("1.34")
  }
  
  public var products: [BuildProduct] {
    [
      .bin("tar"),
    ]
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://ftp.gnu.org/gnu/tar/tar-latest.tar.xz")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ftp.gnu.org/gnu/tar/tar-\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure()
    try env.make()
    try env.make("install")
  }

}
