import BuildSystem

public struct OpusTools: Package {
  
  public init() {}
  
  public var defaultVersion: PackageVersion {
    "0.2"
  }
  
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-tools-\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    var libraryType: PackageLibraryBuildType? = .all

    if order.target.system == .macCatalyst {
      libraryType = .static // auto tools don't support catalyst shared lib
    }
    
    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Flac.self),
        .runTime(Ogg.self),
        .runTime(Opus.self),
        .runTime(Opusenc.self),
        .runTime(Opusfile.self)
      ],
      products: [
        .bin("opusdec"),
        .bin("opusenc"),
        .bin("opusinfo"),
      ],
      supportedLibraryType: libraryType
    )
  }
  
  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()
    
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )
    
    try env.make()
    try env.make("install")
  }
  
}
