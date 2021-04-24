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
      dependencies: PackageDependencies(packages: .runTime(Lsmash.self))
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.changingDirectory("VapourSynth", block: { _ in
      try env.configure(
      )

      try env.make()

      try env.make("install")
    })
  }

}
