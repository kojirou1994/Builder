import BuildSystem

public struct Vmaf: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    "10"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-VMAF/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-VMAF/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Ninja.self)
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try replace(contentIn: "meson.build",
                matching: "join_paths(vapoursynth_dep.get_pkgconfig_variable('libdir'), 'vapoursynth')",
                with: "join_paths(get_option('prefix'), get_option('libdir'), 'vapoursynth')")

    try context.inRandomDirectory { _ in
      try context.meson("..")

      try context.launch("ninja")
      try context.launch("ninja", "install")
    }
  }
}
