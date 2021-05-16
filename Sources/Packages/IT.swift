import BuildSystem

public struct IT: Package {
  public init() {}

  #if os(macOS)
  public var defaultVersion: PackageVersion {
    .stable("1.2")
  }
  #endif

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-IT/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-IT/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with context: BuildContext) throws {
    try context.launch("chmod", "+x", "configure")
    try context.launch(path: "./configure", "--install=\(context.prefix.lib.appendingPathComponent("vapoursynth").path)")

    try context.make()
    try context.make("install")
  }
}
