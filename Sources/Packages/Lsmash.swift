import BuildSystem

public struct Lsmash: Package {
  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("2.14.5")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://github.com/l-smash/l-smash/archive/refs/heads/master.zip")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://github.com/l-smash/l-smash/archive/refs/tags/v\(version.toString(includeZeroPatch: true)).tar.gz")
  }

  public func build(with env: BuildEnvironment) throws {

    #if os(macOS)
    try replace(contentIn: "configure", matching: ",--version-script,liblsmash.ver", with: "")
    #endif

    try env.configure(
      configureEnableFlag(env.libraryType.buildStatic, "static", defaultEnabled: true),
      configureEnableFlag(env.libraryType.buildShared, "shared", defaultEnabled: false)
    )

    try env.make()

    try env.make(enableCli ? "install" : "install-lib")
  }

  @Flag()
  var enableCli: Bool = false

  public var tag: String {
    enableCli ? "CLI" : ""
  }

}
