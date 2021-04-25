import BuildSystem

public struct Corkscrew: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://deb.debian.org/debian/pool/main/c/corkscrew/corkscrew_\(version.toString(includeZeroPatch: false)).orig.tar.gz")
    }

    return .init(source: source, supportedLibraryType: nil)
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure()
    
    try env.make()

    try env.make("install")
  }

}
