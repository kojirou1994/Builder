import BuildSystem

public struct Iperf2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.2.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://downloads.sourceforge.net/project/iperf2/iperf-\(version.toString(includeZeroPatch: false)).tar.gz")
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
      configureEnableFlag(false, CommonOptions.dependencyTracking)
    )

    try context.make("install")
  }

}
