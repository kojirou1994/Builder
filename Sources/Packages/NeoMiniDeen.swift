import BuildSystem

public struct NeoMiniDeen: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("10")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/MiniDeen/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/MiniDeen/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build", block: { _ in
      try env.cmake(toolType: .ninja, "..")

      try env.make(toolType: .ninja)
    })
  }
}
