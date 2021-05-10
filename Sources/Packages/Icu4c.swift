import BuildSystem

public struct Icu4c: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "69.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/unicode-org/icu/archive/refs/tags/release-\(version.toString(includeZeroMinor: false, includeZeroPatch: false, versionSeparator: "-")).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    let buildTools = env.order.target.system == .linuxGNU
    || env.order.target.system == .macOS

    try env.changingDirectory("icu4c/source") { _ in
      try env.autoreconf()

      try env.configure(
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag,
        configureEnableFlag(false, "samples"),
        configureEnableFlag(env.strictMode, "tests"),
        configureEnableFlag(buildTools, "tools"),
        configureEnableFlag(buildTools, "extras"),
        "--with-library-bits=64"
      )

      try env.make()
      if env.strictMode {
        try env.make("check")
      }
      try env.make("install")
    }
  }

}
