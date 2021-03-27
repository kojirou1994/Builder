import BuildSystem

struct Zvbi: Package {

  var defaultVersion: PackageVersion {
    .stable("0.2.35")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    let versionString = version.toString()
    return .tarball(url: "https://nchc.dl.sourceforge.net/project/zapping/zvbi/\(versionString)/zvbi-\(versionString).tar.bz2")
  }

  func supports(target: BuildTriple) -> Bool {
    switch target.system {
    case .macOS, .linuxGNU:
      return true
    default: return false
    }
  }

  func build(with env: BuildEnvironment) throws {

    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      nil
    )

    try env.make()

    try env.make("install")
  }

}
