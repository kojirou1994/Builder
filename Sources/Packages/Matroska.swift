import BuildSystem

public struct Matroska: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("1.6.3")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    let ext: String
    if version >= "1.4.8" {
      ext = "xz"
    } else if version >= "0.7.0" {
      ext = "bz2"
    } else {
      // older version not important
      ext = "gz"
    }
    return .tarball(url: "https://dl.matroska.org/downloads/libmatroska/libmatroska-\(version.toString()).tar.\(ext)")
  }

  public func build(with env: BuildEnvironment) throws {
    if env.libraryType.buildStatic {
      try env.changingDirectory("build_static", block: { _ in
        try env.cmake(
          toolType: .ninja,
          ".."
        )

        try env.make(toolType: .ninja)
        try env.make(toolType: .ninja, "install")
      })
    }

    if env.libraryType.buildShared {
      try env.changingDirectory("build_shared", block: { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(true, "BUILD_SHARED_LIBS")
        )

        try env.make(toolType: .ninja)
        try env.make(toolType: .ninja, "install")
      })
    }
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Ebml.self))
  }

}
