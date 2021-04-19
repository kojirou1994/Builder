import BuildSystem

public struct Imath: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("3.0.1")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/AcademySoftwareFoundation/Imath/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {

    func build(shared: Bool) throws {
      try env.changingDirectory(env.randomFilename) { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(false, "BUILD_TESTING"),
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS"),
          cmakeDefineFlag("", "IMATH_STATIC_LIB_SUFFIX")
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
