import BuildSystem

public struct GasPreprocessor: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/libav/gas-preprocessor.git")
    case .stable:
      throw PackageRecipeError.unsupportedVersion
    }

    return .init(
      source: source,
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try context.mkdir(context.prefix.bin)
    try context.copyItem(at: URL(fileURLWithPath: "gas-preprocessor.pl"), toDirectory: context.prefix.bin)
  }
}
