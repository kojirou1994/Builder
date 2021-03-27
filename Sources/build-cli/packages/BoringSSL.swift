import BuildSystem

struct BoringSSL: Package {

  var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/google/boringssl/archive/master.zip")
  }

  func build(with env: BuildEnvironment) throws {

    try env.changingDirectory("build", block: { _ in

      try env.cmake(
        toolType: .ninja,
        "..",
        nil
      )

      try env.make(toolType: .ninja)
//      try env.make(toolType: .ninja, "install")
    })

  }
}
