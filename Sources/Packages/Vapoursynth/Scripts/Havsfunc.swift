import BuildSystem

public struct Havsfunc: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/HomeOfVapourSynthEvolution/havsfunc.git")
    case .stable:
      throw PackageRecipeError.unsupportedVersion
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Vapoursynth.self),
        .runTime(Mvsfunc.self),
        .runTime(Adjust.self),
        .runTime(Nnedi3.self),
        .runTime(Znedi3.self),
        .runTime(MiscFilters.self),
        .runTime(Nnedi3cl.self),
        .runTime(Mvtools.self),
        .runTime(Dfttest.self),
        .runTime(Eedi2.self),
        .runTime(Fmtconv.self),
        .runTime(Eedi3.self),
        .runTime(Sangnom.self),
        .runTime(Deblock.self),
        .runTime(KNLMeansCL.self),
        .runTime(TTempSmooth.self),
        .runTime(Ctmf.self),
        .runTime(FFT3DFilter.self),
        .runTime(AddGrain.self),
        .runTime(DCTFilter.self),
        .runTime(Hqdn3d.self),
        .runTime(Fluxsmooth.self),
        .runTime(Asharp.self),
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try Vapoursynth.install(script: "havsfunc.py", context: context)
  }
}
