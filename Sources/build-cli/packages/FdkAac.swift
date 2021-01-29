import BuildSystem

struct FdkAac: Package {

  var version: PackageVersion {
    .stable("2.0.1")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    guard let v = version.stableVersion else { return nil }
    return .tarball(url: "https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-\(v).tar.gz")
  }

  func build(with env: BuildEnvironment) throws {
    try env.autogen()
    try env.configure(
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(example, "example")
    )
    try env.make("install")
  }
  
  @Flag(inversion: .prefixedEnableDisable, help: "Enable example encoding program.")
  var example: Bool = false

}
