import BuildSystem

public struct LsmashWorks: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/VFR-maniac/L-SMASH-Works/archive/refs/heads/master.zip")
    case .stable:
      throw PackageRecipeError.unsupportedVersion
    }

    return .init(
      source: source,
      dependencies: [.runTime(Lsmash.self)]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.changingDirectory("VapourSynth") { _ in
      try context.configure(
      )

      try context.make()

      try context.make("install")
    }
  }

}
