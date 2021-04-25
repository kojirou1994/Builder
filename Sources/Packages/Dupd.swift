import BuildSystem

public struct Dupd: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.7.0"
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
      dependencies: .init(packages: .runTime(Openssl.self))
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.make("install", "INSTALL_PREFIX=\(env.prefix.root.path)")
  }
}
