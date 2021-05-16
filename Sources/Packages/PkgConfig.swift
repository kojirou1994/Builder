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
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.configure(
      configureWithFlag(true, "internal-glib"),
      configureEnableFlag(false, "host-tool")
    )

    try context.make()
    try context.make("install")
  }

}
