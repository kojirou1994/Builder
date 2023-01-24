import BuildSystem

public struct MediaBundle: AbstractPackage {

  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    .init(
      source: .empty,
      dependencies: [
        .runTime(Ffmpeg { $0.preset = .allYeah } ),
        .runTime(VapoursynthBundle.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

  }

}
