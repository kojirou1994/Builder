import BuildSystem

public struct Fluxsmooth: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/dubhater/vapoursynth-fluxsmooth/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/dubhater/vapoursynth-fluxsmooth/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
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

    try Vapoursynth.install(plugin: context.prefix.appending("lib", "libfluxsmooth"), context: context)
  }
}
