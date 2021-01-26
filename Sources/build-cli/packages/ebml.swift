import BuildSystem

struct Ebml: Package {
  var version: PackageVersion {
    .stable("1.4.1")
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

  var source: PackageSource {
    .tarball(url: "https://dl.matroska.org/downloads/libebml/libebml-1.4.1.tar.xz")
  }
}
