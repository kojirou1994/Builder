import BuildSystem

struct Mediainfo: Package {
  var defaultVersion: PackageVersion {
    .stable("21.03")
  }

  func stablePackageSource(for version: Version) -> PackageSource? {
    let versionString = version.toString(includeZeroMinor: true, includeZeroPatch: false, numberWidth: 2)
    return .tarball(url: "https://old.mediaarea.net/download/binary/mediainfo/\(versionString)/MediaInfo_CLI_\(versionString)_GNU_FromSource.tar.xz")
  }

  func build(with env: BuildEnvironment) throws {
    // build alone
    try env.changingDirectory("ZenLib/Project/GNU/Library", block: { _ in
      try env.launch(path: "autogen.sh")

      try env.configure(
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag
      )

      try env.make()
      try env.make("install")
    })

    try env.changingDirectory("MediaInfoLib/Project/GNU/Library", block: { _ in
      try env.launch(path: "autogen.sh")

      try env.configure(
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag,
        "--with-libcurl"
      )

      try env.make()
      try env.make("install")
    })

    try env.changingDirectory("MediaInfo/Project/GNU/CLI", block: { _ in
      try env.launch(path: "autogen.sh")
      
      try env.configure(
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag,
        configureEnableFlag(env.libraryType.buildStatic, "staticlibs")
      )

      try env.make()
      try env.make("install")
    })

  }
}
