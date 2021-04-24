import BuildSystem

public struct Vorbis: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.7"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies:
        .init(packages: [.runTime(Ogg.self)], otherPackages: [.brewAutoConf])
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(examples, "examples"),
      configureEnableFlag(docs, "docs"),
      configureEnableFlag(false, "oggtest"),
      "--with-ogg-libraries=\(env.dependencyMap[Ogg.self].lib.path)",
      "--with-ogg-includes=\(env.dependencyMap[Ogg.self].include.path)"
    )
    try env.make("install")
  }

  @Flag(inversion: .prefixedEnableDisable, help: "build the examples.")
  var examples: Bool = false

  @Flag(inversion: .prefixedEnableDisable, help: "build the documentation.")
  var docs: Bool = false

  public var tag: String {
    [
      examples ? "examples" : "",
      docs ? "docs" : "",
    ].joined()
  }

}
