import BuildSystem

public struct Nasm: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("2.15.05")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    var verStr = "\(version.major).\(String(format: "%02d", version.minor))"
    if version.patch != 0 {
      verStr.append(".\(String(format: "%02d", version.patch))")
    }
    return .tarball(url: "https://www.nasm.us/pub/nasm/releasebuilds/\(verStr)/nasm-\(verStr).tar.xz")
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autogen()
    try env.configure()
    try env.make("rdf")
    try env.make("install", "install_rdf")
  }
}
