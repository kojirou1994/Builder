import BuildSystem

public struct KNLMeansCL: Package {
  public init() {}

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/Khanattila/KNLMeansCL/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/Khanattila/KNLMeansCL/archive/refs/tags/v\(version.toString()).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {
    if env.version == .head || env.version.stableVersion! > "1.1.1" {
      try env.changingDirectory("build", block: { _ in
        try env.meson("..")

        try env.launch("ninja")
        try env.launch("ninja", "install")
      })
    } else {
      try env.launch(path: "./configure", "--install=\(env.prefix.lib.appendingPathComponent("vapoursynth").path)")

      try env.make()
      try env.make("install")
    }

  }
}
