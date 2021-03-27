import BuildSystem

public struct NeoFFT3D: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("10")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/neo_FFT3D/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/neo_FFT3D/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build", block: { _ in
      try env.cmake(toolType: .ninja, "..")

      try env.make(toolType: .ninja)
      let filename = "libneo-fft3d.\(env.target.system.sharedLibraryExtension)"

      let installDir = env.prefix.lib.appendingPathComponent("vapoursynth")
      try env.fm.createDirectory(at: installDir)

      try env.fm.copyItem(at: URL(fileURLWithPath: filename), toDirectory: installDir)
    })
  }
}
