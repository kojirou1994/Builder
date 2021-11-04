import BuildSystem

public struct Hqdn3d: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.0.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/theChaosCoder/vapoursynth-hqdn3d/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/theChaosCoder/vapoursynth-hqdn3d/archive/refs/tags/r\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Vapoursynth.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autogen()
    try context.configure()

    try context.make()
    try context.make("install")

    try Vapoursynth.install(plugin: context.prefix.appending("lib", "libhqdn3d"), context: context)
  }
}
