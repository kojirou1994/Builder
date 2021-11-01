import BuildSystem

public struct Meson: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    .init(
      source: .empty,
      dependencies: [
        .runTime(Python.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.launch("pip3", "install", "meson")
  }
  
}
