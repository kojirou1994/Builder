import BuildSystem

public struct GnuTar: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.34"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://ftp.gnu.org/gnu/tar/tar-latest.tar.xz")
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/tar/tar-\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      products: [
        .bin("tar"),
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure()
    try env.make()
    try env.make("install")
  }

}
