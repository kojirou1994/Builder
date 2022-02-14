import BuildSystem

public struct Opencore: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.1.5"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ]
    )
  }
  
  public func build(with context: BuildContext) throws {

    try context.autoreconf()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    try context.make("install")
  }

}
