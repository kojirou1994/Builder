import BuildSystem

public struct Curve: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-Curve/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-Curve/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: .buildTool(Ninja.self)
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try replace(contentIn: "meson.build",
                matching: "join_paths(vapoursynth_dep.get_pkgconfig_variable('libdir'), 'vapoursynth')",
                with: "join_paths(get_option('prefix'), get_option('libdir'), 'vapoursynth')")

    try env.changingDirectory("build", block: { _ in
      try env.meson("..")

      try env.launch("ninja")
      try env.launch("ninja", "install")
    })
  }
}