import BuildSystem

public struct Giflib: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
//    .stable("5.1.4")
    .stable("5.2.1")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://downloads.sourceforge.net/project/giflib/giflib-\(version.toString()).tar.gz",
             patches: [.init(url: "https://sourceforge.net/p/giflib/bugs/_discuss/thread/4e811ad29b/c323/attachment/Makefile.patch", sha256: "")])
  }

  public func build(with env: BuildEnvironment) throws {
    // parallel not supported
    let prefix = "PREFIX=\(env.prefix.root.path)"
    try env.launch("make", "install", prefix)
    try env.launch("make", "install-man", prefix)

    try env.autoRemoveUnneedLibraryFiles()
//    try env.autogen()
//    try env.configure(
//      configureEnableFlag(false, CommonOptions.dependencyTracking),
//      env.libraryType.sharedConfigureFlag,
//      env.libraryType.staticConfigureFlag
//    )
  }


}
