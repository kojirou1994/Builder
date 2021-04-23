import BuildSystem

public struct Ass: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("0.15.0")
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/libass/libass/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/libass/libass/archive/refs/tags/\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .packages(
        .init(Freetype.self),
        .init(Harfbuzz.self),
        .init(Fribidi.self)
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "fontconfig"),
      configureEnableFlag(env.target.system != .linuxGNU, "require-system-font-provider", defaultEnabled: true)
    )

    try env.make()
    try env.make("install")
  }

}
