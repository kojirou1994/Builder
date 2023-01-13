import BuildSystem

public struct AutoconfArchive: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2022.09.03"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-\(version.toString(numberWidth: 2)).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [.runTime(Autoconf.self)],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try context.configure()
    try context.make("install")
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    if order.system == .linuxGNU {
      return .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [])
    }
    return nil
  }

}
