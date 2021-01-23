import BuildSystem

struct Ebml: Package {
  var version: PackageVersion {
    .stable("1.4.1")
  }

  func build(with builder: Builder) throws {
    // build alone
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
    .tarball(url: "https://dl.matroska.org/downloads/libebml/libebml-1.4.1.tar.xz")
  }
}
