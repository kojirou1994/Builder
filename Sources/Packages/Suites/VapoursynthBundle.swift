import BuildSystem

public struct VapoursynthBundle: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    .init(
      source: .empty,
      dependencies: [
        .runTime(Vapoursynth.self),
        .runTime(Vivtc.self),
        .runTime(Bestaudiosource.self),
        .runTime(Imwri.self),
        .runTime(Havsfunc.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

  }

}
