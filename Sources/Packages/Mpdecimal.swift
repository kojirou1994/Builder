import BuildSystem

public struct Mpdecimal: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.5.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
      ]
    )
  }

  @Flag(inversion: .prefixedEnableDisable, help: "enable building libmpdec++")
  var cxx: Bool = false

  public func build(with context: BuildContext) throws {
    try context.configure(
      context.order.libraryType.sharedConfigureFlag,
      configureEnableFlag(cxx, "cxx"),
      nil
    )

    try context.make()
    try context.make("install")
    try context.autoRemoveUnneedLibraryFiles()
  }
}
