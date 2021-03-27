import BuildSystem

public struct Fmtconv: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("22")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/EleonoreMizo/fmtconv/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/EleonoreMizo/fmtconv/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build/unix", block: { _ in
      try env.autogen()

      try env.configure(
        
      )

      try env.make()
      try env.make("install")
    })
  }
}
