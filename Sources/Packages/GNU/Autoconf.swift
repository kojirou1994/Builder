import BuildSystem

public struct Autoconf: Package {

  public init() {}

  /*
   automake won't compile when autoconf > 2.69:
   https://savannah.gnu.org/support/index.php?110397
   */
  public var defaultVersion: PackageVersion {
    "2.69"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/autoconf/autoconf-\(version.toString(includeZeroPatch: false)).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [.buildTool(M4.self)],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {

    try context.configure(

    )

    try context.make()
    try context.make("install")
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    if order.system == .linuxGNU {
      return .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [])
    }
    return nil
  }

}
