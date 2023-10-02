import BuildSystem

public struct Libde265: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.0.12"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/strukturag/libde265.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/strukturag/libde265/releases/download/v\(version)/libde265-\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "encoder"),
      configureEnableFlag(false, "dec265"),
      configureEnableFlag(false, "sherlock265")
    )

    try context.make()
    try context.make("install")
  }

}
