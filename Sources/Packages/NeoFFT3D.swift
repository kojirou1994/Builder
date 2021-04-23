import BuildSystem

public struct NeoFFT3D: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "10"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/neo_FFT3D/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/HomeOfAviSynthPlusEvolution/neo_FFT3D/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .packages(
        .init(Cmake.self, options: .init(buildTimeOnly: true)),
        .init(Ninja.self, options: .init(buildTimeOnly: true))
      ),
      supportedLibraryType: .shared
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename, block: { _ in
      try env.cmake(toolType: .ninja, "..")

      try env.make(toolType: .ninja)
      let filename = "libneo-fft3d.\(env.target.system.sharedLibraryExtension)"

      let installDir = env.prefix.lib.appendingPathComponent("vapoursynth")
      try env.fm.createDirectory(at: installDir)

      try env.fm.copyItem(at: URL(fileURLWithPath: filename), toDirectory: installDir)
    })
  }
}
