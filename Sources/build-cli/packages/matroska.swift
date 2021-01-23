import BuildSystem

struct Matroska: Package {
  var version: PackageVersion {
    .stable("1.6.2")
  }

  func build(with builder: Builder) throws {
    if builder.settings.library.buildStatic {
      try builder.changingDirectory("build_static", block: { _ in
        try builder.cmake(
          ".."
        )

        try builder.make()
        try builder.make("install")
      })
    }

    if builder.settings.library.buildShared {
      try builder.changingDirectory("build_shared", block: { _ in
        try builder.cmake(
          "..",
          cmakeFlag(true, "BUILD_SHARED_LIBS")
        )

        try builder.make()
        try builder.make("install")
      })
    }
  }

  var source: PackageSource {
    .tarball(url: "https://dl.matroska.org/downloads/libmatroska/libmatroska-1.6.2.tar.xz")
  }

  var dependencies: [Package] {
    [Ebml.defaultPackage()]
  }

}
