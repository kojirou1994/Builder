import BuildSystem

public struct Opus: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/xiph/opus.git")
    case .stable(let version):
      let includeZeroPatch: Bool
      if version < "1.1" {
        includeZeroPatch = true
      } else {
        includeZeroPatch = false
      }
      source = .tarball(url: "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-\(version.toString(includeZeroPatch: includeZeroPatch)).tar.gz")
    }

    let dependencies: [PackageDependency?]

    if order.version > "1.3.1" {
      dependencies = [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ]
    } else {
      dependencies = [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ]
    }

    return .init(
      source: source,
      dependencies: dependencies,
      products: [
        .library(name: "libopus", headers: ["opus"]),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    if env.order.version > "1.3.1" {
      func build(shared: Bool) throws {
        try env.inRandomDirectory { _ in
          try env.cmake(
            toolType: .ninja,
            "..",
            cmakeOnFlag(true, "OPUS_CUSTOM_MODES"),
            cmakeOnFlag(shared, "BUILD_SHARED_LIBS"),
            cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR")
          )

          try env.make(toolType: .ninja)
          try env.make(toolType: .ninja, "install")
        }
      }

      try build(shared: env.libraryType.buildShared)
      if env.libraryType == .all {
        try build(shared: false)
      }
    } else {
      try env.autoreconf()

      try env.fixAutotoolsForDarwin()

      try env.configure(
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag,
        configureEnableFlag(true, "custom-modes"),
        configureEnableFlag(env.strictMode, "extra-programs"),
        configureEnableFlag(false, "doc")
      )

      try env.make()
      if env.canRunTests {
        try env.make("check")
      }
      try env.make("install")
    }

  }

}
