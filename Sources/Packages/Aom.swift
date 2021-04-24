import BuildSystem

public struct Aom: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("3.0.0")
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://aomedia.googlesource.com/aom")
    case .stable(let version):
      source = .repository(url: "https://aomedia.googlesource.com/aom", requirement: .tag("v\(version.toString())"))
    }

    return .init(
      source: source,
      dependencies:
        .init(packages: [
          .buildTool(Cmake.self),
          .buildTool(Ninja.self),
          .buildTool(Yasm.self)
        ])
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.changingDirectory(env.randomFilename) { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
//        cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_RPATH"),
        cmakeOnFlag(false, "ENABLE_DOCS"),
        cmakeOnFlag(true, "ENABLE_EXAMPLES"),
        cmakeOnFlag(false, "ENABLE_TESTDATA"),
        cmakeOnFlag(false, "ENABLE_TESTS"),
        cmakeOnFlag(false, "ENABLE_TOOLS"),
        cmakeOnFlag(env.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    }

    try env.autoRemoveUnneedLibraryFiles()
  }

}
