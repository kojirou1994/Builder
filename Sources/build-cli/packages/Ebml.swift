import BuildSystem

struct Ebml: Package {
  var defaultVersion: PackageVersion {
    .stable("1.4.2")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://dl.matroska.org/downloads/libebml/libebml-\(version.toString()).tar.xz")
  }
  
  var products: [BuildProduct] {
    [.library(name: "libebml", headers: ["ebml"])]
  }

  func build(with env: BuildEnvironment) throws {
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
