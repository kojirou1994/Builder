import BuildSystem

public struct Mvsfunc: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/AmusementClub/mvsfunc.git")
    case .stable:
      throw PackageRecipeError.unsupportedVersion
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Vapoursynth.self),
        .runTime(Bm3d.self),
        .runTime(Fmtconv.self),
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try Vapoursynth.install(script: "mvsfunc.py", context: context)
  }
}
