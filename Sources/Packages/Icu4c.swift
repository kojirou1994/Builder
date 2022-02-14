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

  public func build(with context: BuildContext) throws {

    let buildTools = context.order.system == .linuxGNU
    || context.order.system == .macOS

    var crossBuild: String?
    if context.isBuildingCross {
      try context.inRandomDirectory { cwd in
        crossBuild = configureWithFlag(cwd.path, "cross-build")

        let savedEnv = context.environment
        defer {
          context.environment = savedEnv
        }
        context.environment.remove(.cflags, .cxxflags, .ldflags)

        let platform: String
        switch TargetSystem.native {
        case .macOS:
          platform = "MacOSX"
        case .linuxGNU:
          platform = "Linux"
        default: fatalError()
        }
        try context.launch(path: "../icu4c/source/runConfigureICU", platform)
        try context.make()
      }
    }

    try context.changingDirectory("icu4c/source") { cwd in
      try context.autoreconf()

      try context.fixAutotoolsForDarwin()

      try context.configure(
        context.libraryType.staticConfigureFlag,
        context.libraryType.sharedConfigureFlag,
        configureEnableFlag(false, "samples"),
        configureEnableFlag(context.strictMode, "tests"),
        configureEnableFlag(buildTools, "tools"),
        configureEnableFlag(buildTools, "extras"),
        crossBuild
      )

      try context.make()
      if context.strictMode {
        try context.make("check")
      }
      try context.make("install")
    }
  }

}
