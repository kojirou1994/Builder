import BuildSystem

public struct Rmff: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.6.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://www.bunkus.org/videotools/librmff/sources/librmff-\(version.toString()).tar.bz2")
    }

    return .init(
      source: source,
      supportedLibraryType: .static
    )
  }

  public func build(with context: BuildContext) throws {
    try context.make("install", "CC=\(context.cc)", "prefix=\(context.prefix.root.path)")
  }

}
