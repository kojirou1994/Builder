import BuildSystem

public struct Eedi3: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "4"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-EEDI3/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-EEDI3/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .pip(["meson"]),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Vapoursynth.self),
        .runTime(Boost.self),
      ],
      supportedLibraryType: .shared
    )
  }

  /*
   Requires Boost unless specify -Dopencl=false.
   */
  public func build(with context: BuildContext) throws {
    try replace(contentIn: "meson.build",
                matching: "join_paths(vapoursynth_dep.get_pkgconfig_variable('libdir'), 'vapoursynth')",
                with: "join_paths(get_option('prefix'), get_option('libdir'), 'vapoursynth')")

    try context.changingDirectory(context.randomFilename) { _ in
      try context.meson("..")

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }
}
