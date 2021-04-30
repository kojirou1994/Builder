public enum PackageRecipeError: Error {
  case unsupportedVersion
  case unsupportedTarget
}

public struct PackageRecipe {

  public init(source: PackageSource,
              dependencies: [PackageDependency?] = [],
              supportsBitcode: Bool = true,
              products: [PackageProduct?] = [],
              supportedLibraryType: PackageLibraryBuildType? = .all) {
    self.source = source
    self.dependencies = dependencies.compactMap { $0 }
    self.supportsBitcode = supportsBitcode
    self.products = products.compactMap { $0 }
    self.supportedLibraryType = supportedLibraryType
  }

  public let source: PackageSource
  public let dependencies: [PackageDependency]
  public let supportsBitcode: Bool
  public let products: [PackageProduct]
  public let supportedLibraryType: PackageLibraryBuildType?
}
