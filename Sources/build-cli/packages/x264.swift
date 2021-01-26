import BuildSystem

struct x264: Package {
  func build(with env: BuildEnvironment) throws {
    try env.configure(
      enableShared ? "--enable-shared" : nil,
      "--enable-static",
      "--enable-strip",
      "--disable-avs",
      //      "--disable-swscale", /* libavformat is not supported without swscale support */
      enableLibav ? nil : "--disable-lavf",
      "--disable-ffms",
      "--disable-gpac",
      enableLsmash ? nil : "--disable-lsmash")
    
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

  var dependencies: PackageDependency {
    var deps = [Package]()
    if enableLsmash {
      deps.append(Lsmash.defaultPackage())
    }
    if enableLibav {
      deps.append(Ffmpeg.minimalDecoder)
    }
    return .packages(deps)
  }

  @Flag()
  var enableLsmash: Bool = false
  @Flag()
  var enableLibav: Bool = false
  @Flag()
  var enableShared: Bool = false

  func validate() throws {
    if enableLibav, enableShared {
      throw ValidationError("shared conflicts with libav")
    }
  }
}
