import BuildSystem

public struct M4: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.4.19"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    switch order.system {
    case .tvOS, .tvSimulator,
         .watchOS, .watchSimulator:
      throw PackageRecipeError.unsupportedTarget
    default:
      break
    }

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "http://git.savannah.gnu.org/r/m4.git")
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/m4/m4-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {

    try context.configure()

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
