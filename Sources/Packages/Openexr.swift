import BuildSystem

public struct Openexr: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("2.5.5")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/AcademySoftwareFoundation/openexr/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    let srcRoot: String
    if case .stable(let stableVersion) = env.version,
       stableVersion < "3.0.0" {
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
    if case .stable(let stableVersion) = version,
       stableVersion < "3.0.0" {
      return .packages(
        .init(Ilmbase.self)
      )
    } else {
      return .packages(
        .init(Imath.self)
      )
    }
  }

}
