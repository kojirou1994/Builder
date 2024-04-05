import BuildSystem

public struct Opus: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.5.1"
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
        .buildTool(M4.self),
      ]
    }

    return .init(
      source: source,
      dependencies: dependencies,
      products: [
        .library(name: "opus", libname: "opus", headerRoot: "opus", headers: [], shimedHeaders: []),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    if context.order.version > "1.3.1" {
      func build(shared: Bool) throws {
        try context.inRandomDirectory { _ in
          try context.cmake(
            toolType: .ninja,
            "..",
            cmakeOnFlag(true, "OPUS_CUSTOM_MODES"),
            cmakeOnFlag(shared, "BUILD_SHARED_LIBS")
          )

          try context.make(toolType: .ninja)
          try context.make(toolType: .ninja, "install")
        }
      }

      try build(shared: context.libraryType.buildShared)
      if context.libraryType == .all {
        try build(shared: false)
      }
    } else {
      try context.autoreconf()

      try context.fixAutotoolsForDarwin()

      try context.configure(
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        context.libraryType.staticConfigureFlag,
        context.libraryType.sharedConfigureFlag,
        configureEnableFlag(true, "custom-modes"),
        configureEnableFlag(context.strictMode, "extra-programs"),
        configureEnableFlag(false, "doc")
      )

      try context.make()
      if context.canRunTests {
        try context.make("check")
      }
      try context.make("install")
    }

  }

}
