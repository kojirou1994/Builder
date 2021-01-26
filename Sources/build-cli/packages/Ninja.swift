import BuildSystem

struct Ninja: Package {
  var version: PackageVersion {
    .stable("1.10.2")
  }
  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    switch version {
    case .stable(let v):
      return .tarball(url: "https://github.com/ninja-build/ninja/archive/v\(v).tar.gz", filename: "ninja-\(v).tar.gz")
    default:
      return nil
    }
  }

  func build(with env: BuildEnvironment) throws {
    try env.changingDirectory("build") { _ in
      try env.cmake(
        toolType: .make, 
        ".."
        /* -DBUILD_TESTING */
      )

      try env.make()

      try env.make("install")
    }
  }


}
