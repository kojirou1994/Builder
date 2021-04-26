import BuildSystem

public struct Openssl: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable(.init(major: 1, minor: 1, patch: 1, buildMetadataIdentifiers: ["i"]))
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.target.system {
    case .macOS, .linuxGNU:
      switch order.target.arch {
      case .arm64, .x86_64:
        break
      default:
        throw PackageRecipeError.unsupportedTarget
      }
    default:
      throw PackageRecipeError.unsupportedTarget
    }

    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      var versionString = version.toString(includeZeroMinor: true, includeZeroPatch: true, includePrerelease: false, includeBuildMetadata: false)
      if !version.prereleaseIdentifiers.isEmpty {
        versionString += "-"
        versionString += version.prereleaseIdentifiers.joined(separator: ".")
      } else if !version.buildMetadataIdentifiers.isEmpty {
        versionString += version.buildMetadataIdentifiers.joined(separator: ".")
      }
      source = .tarball(url: "https://www.openssl.org/source/openssl-\(versionString).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with env: BuildEnvironment) throws {

    let os: String
    switch env.target.system {
    case .macOS:
      os = "darwin64-\(env.target.arch.clangTripleString)-cc"
    case .linuxGNU:
      //"linux-x86_64-clang"
      os = "linux-\(env.target.arch.gnuTripleString)"
    default:
      os = env.target.clangTripleString
    }

    try env.launch(
      path: "Configure",
      "--prefix=\(env.prefix.root.path)",
      "--openssldir=\(env.prefix.appending("etc", "openssl").path)",
      env.libraryType.buildShared ? "shared" : "no-shared",
      os,
      "enable-ec_nistp_64_gcc_128"
    )

    try env.make()
    if env.strictMode {
      try env.launch("make", "test")
    }
    try env.make(parallelJobs: 1, "install")
  }

}
