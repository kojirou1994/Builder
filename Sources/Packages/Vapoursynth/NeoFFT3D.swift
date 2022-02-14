import BuildSystem

public struct NeoFFT3D: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "11"
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
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory(context.randomFilename) { _ in
      try context.cmake(toolType: .ninja, "..")

      try context.make(toolType: .ninja)
      let filename = "libneo-fft3d.\(context.order.system.sharedLibraryExtension)"

      let installDir = context.prefix.lib.appendingPathComponent("vapoursynth")
      try context.mkdir(installDir)

      try context.copyItem(at: URL(fileURLWithPath: filename), toDirectory: installDir)
    }
  }
}
