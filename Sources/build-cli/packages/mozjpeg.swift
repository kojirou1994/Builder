import BuildSystem

struct Mozjpeg: Package {
  var version: PackageVersion {
    .stable("4.0.0")
  }

  func build(with builder: Builder) throws {
    try builder.cmake(
      ".",
      builder.settings.library.staticCmakeFlag,
      builder.settings.library.sharedCmakeFlag
    )
    try builder.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/mozilla/mozjpeg/archive/v4.0.0.tar.gz", filename: "mozjpeg-4.0.0.tar.gz")
  }
}
