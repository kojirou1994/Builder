import BuildSystem

struct Fmt: Package {
  var version: PackageVersion {
    .stable("7.1.3")
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
    .tarball(url: "https://github.com/fmtlib/fmt/archive/7.1.3.tar.gz", filename: "fmt-7.1.3.tar.gz")
  }
}
