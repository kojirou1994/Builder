import BuildSystem

public struct Assrender: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.37.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/AmusementClub/assrender.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/AmusementClub/assrender/archive/refs/tags/\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Ass.self),
        .runTime(Vapoursynth.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in
      try context.cmake(toolType: .ninja, "..")

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }

    try Vapoursynth.install(plugin: context.prefix.appending("lib", "vapoursynth", "libassrender"), context: context)
  }
}
