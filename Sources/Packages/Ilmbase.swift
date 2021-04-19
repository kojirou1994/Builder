import BuildSystem

public struct Ilmbase: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("2.5.5")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    if version < "3.0.0" {
      return .tarball(url: "https://github.com/AcademySoftwareFoundation/openexr/archive/refs/tags/v\(version.toString()).tar.gz")
    }
    return nil
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
