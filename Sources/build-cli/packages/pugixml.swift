import BuildSystem

struct Pugixml: Package {
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

  var source: PackageSource {
    .tarball(url: "https://github.com/zeux/pugixml/releases/download/v1.11.4/pugixml-1.11.4.tar.gz")
  }
  var version: PackageVersion {
    .stable("1.11.4")
  }
}
