import BuildSystem

public struct Openssl: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable(.init(major: 1, minor: 1, patch: 1, buildMetadataIdentifiers: ["k"]))
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.target.system {
    case .macOS, .linuxGNU, .macCatalyst:
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
    switch env.order.target.system {
    case .macOS, .macCatalyst:
      os = "darwin64-\(env.order.target.arch.clangTripleString)-cc"
    case .linuxGNU:
      //"linux-x86_64-clang"
      os = "linux-\(env.order.target.arch.gnuTripleString)"
    default:
      os = env.order.target.clangTripleString
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
    if env.libraryType == .shared {
      try env.autoRemoveUnneedLibraryFiles()
    }
  }

}
