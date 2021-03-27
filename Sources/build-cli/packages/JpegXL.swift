import BuildSystem

struct JpegXL: Package {
  var defaultVersion: PackageVersion {
    .head
  }

  var headPackageSource: PackageSource? {
    .tarball(url: "https://gitlab.com/wg1/jpeg-xl/-/archive/master/jpeg-xl-master.tar.gz")
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
