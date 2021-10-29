import BuildSystem

public struct Dupd: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.7.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/jvirkki/dupd/archive/refs/tags/\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [.runTime(Openssl.self)]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.make("install", "INSTALL_PREFIX=\(context.prefix.root.path)")
  }
}
