import BuildSystem

public struct MediaInfo: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "22.12"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroMinor: true, includeZeroPatch: false, numberWidth: 2)
      source = .tarball(url: "https://github.com/MediaArea/MediaInfo/archive/refs/tags/v\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Automake.self),
        .buildTool(Autoconf.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(MediaInfoLib.self),
      ],
      supportsBitcode: false
    )
  }

  public func build(with context: BuildContext) throws {
    if context.libraryType.buildStatic {
      context.environment["PKG_CONFIG"] = "pkg-config --static"
    }

    try context.changingDirectory("Project/GNU/CLI") { _ in

      try replace(contentIn: "configure.ac", matching: """
        test "$(libzen-config Exists)" = "yes"
        """, with: "false")
      try replace(contentIn: "configure.ac", matching: """
        test "$(libmediainfo-config Exists)" = "yes"
        """, with: "false")

      try context.autoreconf()

      try context.fixAutotoolsForDarwin()

      try context.configure()

      try context.make()
      try context.make("install")
    }

  }
}
