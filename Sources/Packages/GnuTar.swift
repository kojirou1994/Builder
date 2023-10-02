import BuildSystem

public struct GnuTar: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.35"
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

  public func build(with context: BuildContext) throws {
    try context.configure()
    try context.make()
    try context.make("install")
  }

}
