import BuildSystem

public struct Rav1e: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("0.4.1")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/xiph/rav1e/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/xiph/rav1e/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    // TODO: add BUILD_TESTING
    /*
     system "cargo", "install", *std_cargo_args
     system "cargo", "cinstall", "--prefix", prefix
     */
    try env.launch("cargo", "install", "--root",
                   env.prefix.root.path,
                   "--path", ".")
    var types: [String?] = []
    switch env.libraryType {
    case .shared, .statik:
      types.append("--library-type")
      types.append(env.libraryType == .shared ? "cdylib" : "staticlib")
    default: break
    }
    try env.launch("cargo",
                   ["cinstall", "--prefix",
                    env.prefix.root.path] + types)
  }


}
