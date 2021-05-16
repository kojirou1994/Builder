import BuildSystem

public struct Libtool: Package {

  public init() {}

  @Flag
  var ltdl: Bool = false

  public var defaultVersion: PackageVersion {
    "2.4.6"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/libtool/libtool-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [.buildTool(M4.self)],
      supportedLibraryType: ltdl ? .all : nil
    )
  }

  public func build(with context: BuildContext) throws {

    try context.configure(
      configureEnableFlag(ltdl && context.libraryType.buildStatic, "static"),
      configureEnableFlag(ltdl && context.libraryType.buildShared, "shared"),
      configureEnableFlag(ltdl, "ltdl-install")
    )

    try context.make()
    try context.make("install")
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    if order.target.system == .linuxGNU {
      return .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [])
    }
    return nil
  }


}
