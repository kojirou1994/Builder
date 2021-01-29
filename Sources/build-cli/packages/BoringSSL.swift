import BuildSystem

struct BoringSSL: Package {
  var version: PackageVersion {
    .stable("master")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    switch version {
    case .stable(let v):
      return .tarball(url: "https://github.com/google/boringssl/archive/master.zip")
    default:
      return nil
    }
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
