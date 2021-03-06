import BuildSystem

public struct M4: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.4.18"
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
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      var patches = [PackagePatch]()
      if order.system == .linuxGNU {
        patches.append(
          .remote(
            url: "https://raw.githubusercontent.com/archlinux/svntogit-packages/19e203625ecdf223400d523f3f8344f6ce96e0c2/trunk/m4-1.4.18-glibc-change-work-around.patch",
            sha256: "fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8"))
      }
      source = .tarball(url: "https://ftp.gnu.org/gnu/m4/m4-\(version.toString()).tar.xz",
                        patches: patches)
    }

    return .init(
      source: source,
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
