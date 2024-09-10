import BuildSystem

public struct LsmashWorks: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/AkarinVS/L-SMASH-Works")
    case .stable:
      throw PackageRecipeError.unsupportedVersion
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Meson.self),
        .buildTool(Ninja.self),
        .buildTool(Cmake.self),
        .buildTool(PkgConfig.self),
        .runTime(Lsmash.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {

    try context.changingDirectory("VapourSynth") { _ in
      try context.inRandomDirectory { _ in
        try context.meson("..")

        try context.make(toolType: .ninja)
        try context.make(toolType: .ninja, "install")
      }
    }
  }

}
