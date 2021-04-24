import BuildSystem

public struct Mediainfo: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "21.03"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      let versionString = version.toString(includeZeroMinor: true, includeZeroPatch: false, numberWidth: 2)
      source = .tarball(url: "https://old.mediaarea.net/download/binary/mediainfo/\(versionString)/MediaInfo_CLI_\(versionString)_GNU_FromSource.tar.xz")
    }

    return .init(
      source: source
    )
  }

  public func build(with env: BuildEnvironment) throws {
    // build alone
    try env.changingDirectory("ZenLib/Project/GNU/Library", block: { _ in
      try env.autogen()

      try env.configure(
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag
      )

      try env.make()
      try env.make("install")
    })

    try env.changingDirectory("MediaInfoLib/Project/GNU/Library", block: { _ in
      try env.autogen()

      try env.configure(
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag,
        "--with-libcurl"
      )

      try env.make()
      try env.make("install")
    })

    try env.changingDirectory("MediaInfo/Project/GNU/CLI", block: { _ in
      try env.autogen()
      
      try env.configure(
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag,
        configureEnableFlag(env.libraryType.buildStatic, "staticlibs")
      )

      try env.make()
      try env.make("install")
    })

  }
}
