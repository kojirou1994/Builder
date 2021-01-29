import BuildSystem

struct Opencore: Package {

  var version: PackageVersion {
    .stable("0.1.5")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    guard let v = version.stableVersion else { return nil }
    return .tarball(url: "https://deac-riga.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-\(v).tar.gz")
  }
  
  func build(with env: BuildEnvironment) throws {

    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag
    )

    try env.make()
    try env.make("install")
  }

}
