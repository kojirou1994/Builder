import BuildSystem

public struct FFT3DFilter: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/kojirou1994/VapourSynth-FFT3DFilter/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/kojirou1994/VapourSynth-FFT3DFilter/archive/refs/tags/R\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    #warning("fftw")
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
    try replace(contentIn: "meson.build",
                matching: "join_paths(vapoursynth_dep.get_pkgconfig_variable('libdir'), 'vapoursynth')",
                with: "join_paths(get_option('prefix'), get_option('libdir'), 'vapoursynth')")

    try context.changingDirectory(context.randomFilename) { _ in
      try context.meson("..")

      try context.launch("ninja")
      try context.launch("ninja", "install")
    }
  }
}
