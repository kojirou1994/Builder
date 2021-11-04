import BuildSystem

public struct Nnedi3cl: Package {

  public init() {}
  
  public var defaultVersion: PackageVersion {
    "8"
  }
  
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-NNEDI3CL.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-NNEDI3CL/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }
    
    return .init(
      source: source,
      dependencies:[
        .buildTool(Meson.self),
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Vapoursynth.self),
        .runTime(Boost.self),
      ],
      supportedLibraryType: .shared
    )
  }
  
  public func build(with context: BuildContext) throws {

    try Vapoursynth.fixMeson()

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

    try context.moveItem(at: context.prefix.appending("share/NNEDI3CL/nnedi3_weights.bin"), to: context.prefix.appending("lib/nnedi3_weights.bin"))
    try Vapoursynth.install(plugin: context.prefix.appending("lib", "vapoursynth", "libnnedi3cl"), context: context)
  }
}
