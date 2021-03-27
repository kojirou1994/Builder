import BuildSystem

struct Pugixml: Package {
  
  var defaultVersion: PackageVersion {
    .stable("1.11.4")
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/zeux/pugixml/archive/refs/heads/master.zip")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/zeux/pugixml/archive/refs/tags/v\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build", block: { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        env.libraryType.buildShared ? cmakeOnFlag(true, env.libraryType.buildStatic ? "BUILD_SHARED_AND_STATIC_LIBS" : "BUILD_SHARED_LIBS") : nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    })
  }
}
