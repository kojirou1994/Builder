import BuildSystem

struct Fmt: Package {
  var defaultVersion: PackageVersion {
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

  func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/fmtlib/fmt/archive/refs/tags/\(version.toString()).tar.gz")
  }
}
