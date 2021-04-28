import BuildSystem

public struct Automake: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.16.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/automake/automake-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(packages: [.buildTool(Autoconf.self), .buildTool(Libtool.self)]),
      supportedLibraryType: nil
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.configure()
    try env.make()
    try env.make("install")

//    try """
//    \(env.dependencyMap[Libtool.self].appending("share", "aclocal").path)
//    """.write(to: env.prefix.appending("share", "aclocal", "dirlist"), atomically: true, encoding: .utf8)
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    if order.target.system == .linuxGNU {
      return .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [])
    }
    return nil
  }

}
