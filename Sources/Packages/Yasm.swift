import BuildSystem

public struct Yasm: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("1.3.0")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/yasm/yasm/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://www.tortall.net/projects/yasm/releases/yasm-\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    if env.version == .head {
      try env.autogen()
    }
    try env.configure()
    try env.make()
    try env.make("install")
  }
}
