import BuildSystem

public struct Fmt: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "7.1.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://github.com/fmtlib/fmt/archive/refs/tags/\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    func build(shared: Bool) throws {
      try env.changingDirectory(env.randomFilename) { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
          cmakeOnFlag(false, "FMT_TEST"),
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS")
        )

        try env.make(toolType: .ninja)
        try env.make(toolType: .ninja, "install")
      }
    }

    try build(shared: env.libraryType.buildShared)
    if env.libraryType == .all {
      try build(shared:false)
    }
  }

}
