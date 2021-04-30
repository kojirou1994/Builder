public enum PackageRecipeError: Error {
  case unsupportedVersion
  case unsupportedTarget
}

public struct PackageRecipe {

  public init(source: PackageSource,
              dependencies: PackageDependencies = .empty,
              supportsBitcode: Bool = true,
              products: [PackageProduct?] = [],
              supportedLibraryType: PackageLibraryBuildType? = .all) {
    self.source = source
    self.dependencies = dependencies
    self.supportsBitcode = supportsBitcode
    self.products = products.compactMap { $0 }
    self.supportedLibraryType = supportedLibraryType
  }

  public let source: PackageSource
  public let dependencies: PackageDependencies
  public let supportsBitcode: Bool
  public let products: [PackageProduct]
  public let supportedLibraryType: PackageLibraryBuildType?
}
