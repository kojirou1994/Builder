import BuildSystem

public struct Ilmbase: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.5.5"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      if version < "3.0.0" {
        source = .tarball(url: "https://github.com/AcademySoftwareFoundation/openexr/archive/refs/tags/v\(version.toString()).tar.gz")
      } else {
        throw PackageRecipeError.unsupportedVersion
      }
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: .buildTool(Cmake.self),
        .buildTool(Ninja.self)
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {

    func build(shared: Bool) throws {
      try env.changingDirectory("IlmBase/" + env.randomFilename) { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(false, "BUILD_TESTING"),
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS"),
          cmakeDefineFlag("", "ILMBASE_STATIC_LIB_SUFFIX")
        )
        try env.make(toolType: .ninja)
        try env.make(toolType: .ninja, "install")
      }
    }

    try build(shared: env.libraryType.buildShared)

    if env.libraryType == .all {
      try build(shared: false)
    }
  }

}
