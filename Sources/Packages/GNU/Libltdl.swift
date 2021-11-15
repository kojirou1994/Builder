import BuildSystem

public struct Libltdl: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    Libtool.defaultPackage.defaultVersion
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    var recipe = try Libtool.defaultPackage.recipe(for: order)
    recipe.supportedLibraryType = .all
    return recipe
  }

  public func build(with context: BuildContext) throws {

    try context.configure(
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "ltdl-install")
    )

    try context.make()
    try context.make("install")

    try context.removeItem(at: context.prefix.bin)
    try context.removeItem(at: context.prefix.share)
  }

}
