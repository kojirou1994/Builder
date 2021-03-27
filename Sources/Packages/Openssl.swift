import BuildSystem

public struct Openssl: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("1.1.1i")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://www.openssl.org/source/openssl-\(version).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {

    try env.launch(
      path: "Configure",
      "--prefix=\(env.prefix.root.path)",
      "--openssldir=\(env.prefix.appending("etc", "openssl").path)",
      env.libraryType.buildShared ? "shared" : "no-shared",
      "darwin64-x86_64-cc",
      "enable-ec_nistp_64_gcc_128"
    )

//    try env.launch("make")
//    try env.launch("make", "test")
    try env.make()
    try env.make("install")
  }

}
