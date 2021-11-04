import BuildSystem

public struct Eedi3: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    if order.target.arch.isARM {
      source = .repository(url: "https://github.com/kojirou1994/VapourSynth-EEDI3.git")
    } else {
      switch order.version {
      case .head:
        source = .repository(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-EEDI3.git")
      case .stable(let version):
        source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-EEDI3/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
      }
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Meson.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Vapoursynth.self),
        .runTime(Boost.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {

    try replace(contentIn: "meson.build",
                matching: "boost_dep = dependency('boost', modules : ['filesystem', 'system'])",
                with: """
cxx = meson.get_compiler('cpp')
boost_dep = [
    cxx.find_library('boost_system'),
    cxx.find_library('boost_filesystem'),
]
""")

    try context.inRandomDirectory { _ in
      try context.meson("..")

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }
}
