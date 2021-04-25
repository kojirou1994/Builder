import BuildSystem

public struct M4: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.4.18"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    switch order.target.system {
    case .tvOS, .tvSimulator,
         .watchOS, .watchSimulator:
      throw PackageRecipeError.unsupportedTarget
    default:
      break
    }
    
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/m4/m4-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      supportedLibraryType: nil
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.configure(

    )

    try env.make()
    try env.make("install")
  }

}
