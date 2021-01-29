import BuildSystem

struct Mediainfo: Package {
  var version: PackageVersion {
    .stable("20.09")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    switch version {
    case .stable(let v):
      return .tarball(url: "https://mediaarea.net/download/binary/mediainfo/\(v)/MediaInfo_CLI_\(v)_GNU_FromSource.tar.bz2", filename: "MediaInfo_CLI_GNU_FromSource.tar.bz2")
    default:
      return nil
    }
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
