import BuildSystem

public struct Ebml: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("1.4.2")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://dl.matroska.org/downloads/libebml/libebml-\(version.toString()).tar.xz")
  }
  
  public var products: [BuildProduct] {
    [.library(name: "libebml", headers: ["ebml"])]
  }

  public func build(with env: BuildEnvironment) throws {
    // build alone
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

}
