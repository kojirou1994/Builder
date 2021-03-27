import BuildSystem

public struct Openssl: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable(.init(major: 1, minor: 1, patch: 1, buildMetadataIdentifiers: ["i"]))
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    var versionString = version.toString(includeZeroMinor: true, includeZeroPatch: true, includePrerelease: false, includeBuildMetadata: false)
    if !version.prereleaseIdentifiers.isEmpty {
      versionString += "-"
      versionString += version.prereleaseIdentifiers.joined(separator: ".")
    } else if !version.buildMetadataIdentifiers.isEmpty {
      versionString += version.buildMetadataIdentifiers.joined(separator: ".")
    }
    return .tarball(url: "https://www.openssl.org/source/openssl-\(versionString).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {

    try env.launch(
      path: "Configure",
      "--prefix=\(env.prefix.root.path)",
      "--openssldir=\(env.prefix.appending("etc", "openssl").path)",
      env.libraryType.buildShared ? "shared" : "no-shared",
      "darwin64-x86_64-cc",
      "enable-ec_nistp_64_gcc_128"
    )

    try env.make()
    if env.safeMode {
      try env.launch("make", "test")
    }
    try env.make("install")
  }

}
