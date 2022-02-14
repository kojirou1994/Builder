import BuildSystem

public struct Fmtconv: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "28"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/EleonoreMizo/fmtconv/archive/refs/tags/r\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .runTime(Vapoursynth.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {
    try context.changingDirectory("build/unix") { _ in
      try context.autogen()

      #warning("check clang")
      try context.configure(
        configureEnableFlag(true, "clang")
      )

      try context.make()
      try context.make("install")

      try Vapoursynth.install(plugin: context.prefix.appending("lib", "libfmtconv"), context: context)
    }
  }
}
