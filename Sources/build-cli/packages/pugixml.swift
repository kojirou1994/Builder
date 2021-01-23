import BuildSystem

struct Pugixml: Package {
  func build(with builder: Builder) throws {
    try builder.changingDirectory("build", block: { _ in
      try builder.cmake(
        "..",
        builder.settings.library.buildShared ? cmakeFlag(true, builder.settings.library.buildStatic ? "BUILD_SHARED_AND_STATIC_LIBS" : "BUILD_SHARED_LIBS") : nil
      )

      try builder.make()
      try builder.make("install")
    })
  }

  var source: PackageSource {
    .tarball(url: "https://github.com/zeux/pugixml/releases/download/v1.11.4/pugixml-1.11.4.tar.gz")
  }
  var version: PackageVersion {
    .stable("1.11.4")
  }
}
