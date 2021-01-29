import BuildSystem

struct Gcrypt: Package {
  func build(with env: BuildEnvironment) throws {
    try env.autogen()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--with-gpg-error-prefix=\(env.dependencyMap[GpgError.self].root.path)",
      configureEnableFlag(env.isBuildingNative, "asm", defaultEnabled: true)
    )

    try env.make()
    try env.make("install")
  }

  var version: PackageVersion {
    .stable("1.8.7")
  }

  var source: PackageSource {
    .tarball(url: "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.7.tar.bz2")
  }

  var dependencies: PackageDependency {
    .packages(GpgError.defaultPackage)
  }

  func supports(target: BuildTriple) -> Bool {
    switch target.system {
    case .macOS:
      return true
    default:
      return false
    }
  }
}
