import BuildSystem

public struct DeLogo: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.4"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-DeLogo/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-DeLogo/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Meson.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Vapoursynth.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {
    try context.launch("chmod", "+x", "configure")
    try context.launch(path: "./configure", "--install=\(context.prefix.lib.appendingPathComponent("vapoursynth").path)")

    try replace(contentIn: "config.mak", matching: "include/vapoursynth", with: "include")
    try context.make()
    try context.make("install")
  }
}
