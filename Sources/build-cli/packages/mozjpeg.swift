import BuildSystem

struct Mozjpeg: Package {
  var version: PackageVersion {
    .stable("4.0.0")
  }

  func build(with env: BuildEnvironment) throws {
    try env.cmake(
      toolType: .ninja,
      ".",
      env.libraryType.staticCmakeFlag,
      env.libraryType.sharedCmakeFlag
    )

    try env.make(toolType: .ninja)
    try env.make(toolType: .ninja, "install")
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/mozilla/mozjpeg/archive/v4.0.0.tar.gz", filename: "mozjpeg-4.0.0.tar.gz")
  }
}
