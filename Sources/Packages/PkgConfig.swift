import BuildSystem

public struct PkgConfig: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.29.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://pkgconfig.freedesktop.org/releases/pkg-config-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .init(packages: [], otherPackages: [.brewAutoConf]),
      supportedLibraryType: nil
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureWithFlag(true, "internal-glib"),
      configureEnableFlag(false, "host-tool"),
//      "--with-system-include-path=\(env.sdkPath!)/usr/include"
      nil
    )

    try env.make()
    try env.make("install")
  }

}
