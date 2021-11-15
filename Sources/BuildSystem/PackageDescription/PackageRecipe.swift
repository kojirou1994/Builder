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

  public var source: PackageSource
  public var dependencies: [PackageDependency]
  public var supportsBitcode: Bool
  public var products: [PackageProduct]
  public var supportedLibraryType: PackageLibraryBuildType?
  public var canBuildAllLibraryTogether: Bool
}
