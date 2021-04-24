import BuildSystem

public struct Openexr: Package {

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
      source = .tarball(url: "https://github.com/AcademySoftwareFoundation/openexr/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: dependencies(for: order.version)
    )
  }

  public func build(with env: BuildEnvironment) throws {
    let srcRoot: String
    if env.version < "3.0.0" {
      srcRoot = "OpenEXR/"
    } else {
      srcRoot = ""
    }

    func build(shared: Bool) throws {
      try env.changingDirectory(srcRoot + env.randomFilename) { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(false, "BUILD_TESTING"),
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS"),
          cmakeDefineFlag("", "OPENEXR_STATIC_LIB_SUFFIX")
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

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    if version < "3.0.0" {
      return PackageDependencies(
        packages: .runTime(Ilmbase.self)
      )
    } else {
      return PackageDependencies(
        packages: .runTime(Imath.self)
      )
    }
  }

}
