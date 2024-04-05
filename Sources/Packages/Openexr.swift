import BuildSystem

public struct Openexr: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
   "3.2.4"
  }

  public static var legacyVersion: PackageVersion {
    "2.5.8"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/AcademySoftwareFoundation/openexr.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/AcademySoftwareFoundation/openexr/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: dependencies(for: order.version),
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {
    let srcRoot: String
    if context.order.version < "3.0.0" {
      srcRoot = "OpenEXR/"
    } else {
      srcRoot = ""
    }

    try context.changingDirectory(srcRoot + context.randomFilename) { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.strictMode, "BUILD_TESTING"),
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeDefineFlag("", "OPENEXR_STATIC_LIB_SUFFIX")
      )
      try context.make(toolType: .ninja)
      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }
      try context.make(toolType: .ninja, "install")
    }
  }

  public func dependencies(for version: PackageVersion) -> [PackageDependency] {
    if version < "3.0.0" {
      return [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .runTime(Ilmbase.self),
        .runTime(Zlib.self),
      ]
    } else {
      return [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .runTime(Imath.self),
        .runTime(Zlib.self),
      ]
    }
  }

}
