import BuildSystem

struct JpegXL: Package {
  var version: PackageVersion {
    .stable("master")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    switch version {
    case .stable(let v):
      return .tarball(url: "https://gitlab.com/wg1/jpeg-xl/-/archive/master/jpeg-xl-master.tar.gz")
    default:
      return nil
    }
  }

  func build(with env: BuildEnvironment) throws {

    try env.launch(path: "deps.sh")

    try env.changingDirectory("build", block: { _ in

      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(false, "BUILD_TESTING"),
        nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    })

  }
}
