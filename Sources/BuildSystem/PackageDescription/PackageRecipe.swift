public enum PackageRecipeError: Error {
  case unsupportedVersion
  case unsupportedTarget
}

public struct PackageRecipe {

  public init(source: PackageSource,
              dependencies: [PackageDependency?] = [],
              supportsBitcode: Bool = true,
              products: [PackageProduct?] = [],
              supportedLibraryType: PackageLibraryBuildType? = .all,
              canBuildAllLibraryTogether: Bool = true) {
    self.source = source
    self.dependencies = dependencies.compactMap { $0 }
    self.supportsBitcode = supportsBitcode
    self.products = products.compactMap { $0 }
    self.supportedLibraryType = supportedLibraryType
    self.canBuildAllLibraryTogether = canBuildAllLibraryTogether
  }

  public let source: PackageSource
  public let dependencies: [PackageDependency]
  public let supportsBitcode: Bool
  public let products: [PackageProduct]
  public let supportedLibraryType: PackageLibraryBuildType?
  public let canBuildAllLibraryTogether: Bool
}
