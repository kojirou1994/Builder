import BuildSystem

public struct Temporalsoften2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    if order.arch.isARM {
      throw PackageRecipeError.unsupportedTarget
    } else {
      switch order.version {
      case .head:
        source = .repository(url: "https://github.com/dubhater/vapoursynth-temporalsoften2.git")
      case .stable(let version):
        source = .tarball(url: "https://github.com/dubhater/vapoursynth-temporalsoften2/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
      }
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Meson.self),
        .buildTool(Cmake.self),
        .buildTool(PkgConfig.self),
        .buildTool(Ninja.self),
        .runTime(Vapoursynth.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in
      try context.meson("..")

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }

    try Vapoursynth.install(plugin: context.prefix.appending("lib", "libtemporalsoften2"), context: context)
  }
}
