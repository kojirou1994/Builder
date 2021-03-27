import BuildSystem

public struct Ffms2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("2.40")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.launch(path: "./autogen.sh")
    try env.configure()

    try env.make("install")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/FFMS/ffms2/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/FFMS/ffms2/archive/refs/tags/\(version.toString(includeZeroPatch: false)).tar.gz")
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Ffmpeg.minimalDecoder))
  }

}
