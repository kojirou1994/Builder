import BuildSystem

struct x264: Package {

  var defaultVersion: PackageVersion {
    .stable("r3027")
  }

  func build(with env: BuildEnvironment) throws {

    let needGas = env.target.arch != .x86_64

    if needGas {
      env.environment["AS"] = "tools/gas-preprocessor.pl -arch \(env.target.arch.gnuTripleString) -- \(env.cc)"
    }

    try env.configure(
      configureEnableFlag(cli, "cli", defaultEnabled: true),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
//      configureEnableFlag(true, "lto"),
      configureEnableFlag(true, "strip"),
      configureEnableFlag(true, "pic"),
      needGas ? "--extra-asflags=\(env.environment["CFLAGS", default: ""])" : nil,

      configureEnableFlag(false, "avs"),
      configureEnableFlag(libav, "swscale", defaultEnabled: true),
      configureEnableFlag(libav, "lavf", defaultEnabled: true),
      /* libavformat is not supported without swscale support */
      configureEnableFlag(false, "ffms"),
      configureEnableFlag(false, "gpac"),
      configureEnableFlag(lsmash, "lsmash", defaultEnabled: true)
    )

    try env.make()

    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://code.videolan.org/videolan/x264/-/archive/stable/x264-stable.tar.bz2")
    //    .branch(repo: "https://code.videolan.org/videolan/x264.git", revision: nil)
  }

  enum Mp4Support: String, ExpressibleByArgument {
    case lsmash
    case gpac
  }

  enum InputSupport: String, ExpressibleByArgument {
    case lavf
    case ffms
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    var deps = [PackageDependency]()
    if lsmash {
      deps.append(.init(Lsmash.self))
    }
    if libav {
      deps.append(.init(Ffmpeg.minimalDecoder))
    }
    return .packages(deps)
  }

  @Flag(inversion: .prefixedEnableDisable)
  var lsmash: Bool = false

  @Flag(inversion: .prefixedEnableDisable)
  var libav: Bool = false

  @Flag(inversion: .prefixedEnableDisable)
  var cli: Bool = false

  var tag: String {
    [
      cli ? "CLI" : "",
      lsmash ? "LSMASH" : "",
      libav ? "LIBAV" : ""
    ].joined()
  }
}
