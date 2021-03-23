import BuildSystem

struct CAres: Package {
  var version: PackageVersion {
    .stable("1.17.1")
  }
  var source: PackageSource {
    packageSource(for: version)!
  }

  var products: [BuildProduct] {
    [
      .bin("acountry"),
      .bin("adig"),
      .bin("ahost"),
      .library(
        name: "libcares",
        headers: [
          "ares_build.h", "ares_dns.h",
          "ares_rules.h", "ares_version.h",
          "ares.h"]),
    ]
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    switch version {
    case .stable(let v):
      return .tarball(url: "https://c-ares.haxx.se/download/c-ares-\(v).tar.gz")
    default:
      return nil
    }
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build") { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(env.libraryType.buildStatic, "CARES_STATIC", defaultEnabled: false),
        cmakeOnFlag(env.libraryType.buildShared, "CARES_SHARED", defaultEnabled: true),
        cmakeOnFlag(env.isBuildingCross, "CARES_STATIC_PIC", defaultEnabled: false)
      )

      try env.make(toolType: .ninja)

      try env.make(toolType: .ninja, "install")
    }
  }


}
