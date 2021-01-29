import BuildSystem

struct Fmt: Package {
  var version: PackageVersion {
    .stable("7.1.3")
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
    .tarball(url: "https://github.com/fmtlib/fmt/archive/7.1.3.tar.gz", filename: "fmt-7.1.3.tar.gz")
  }
}
