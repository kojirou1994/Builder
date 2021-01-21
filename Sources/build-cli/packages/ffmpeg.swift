struct Ffmpeg: Package {
  func build(with builder: Builder) throws {
    try builder.configure(configureOptions(builder: builder))

    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://ffmpeg.org/releases/ffmpeg-4.3.1.tar.xz")!, filename: nil)
  }

  @Option
  private var configure: [String] = []

  @Option
  private var preset: Preset?

  @Option
  private var configureFile: String?

  enum FFmpegDependeny: String, EnumerableFlag {
    case libopus
    case libfdkaac = "libfdk-aac"
    case libvorbis
    case libx264
    case libx265
    case libwebp
    case libaribb24
    case libopencore
    case libass

    case apple

    var isNonFree: Bool {
      switch self {
      case .libfdkaac:
        return true
      default:
        return false
      }
    }

    /*
     EXTERNAL_LIBRARY_GPL_LIST='
     avisynth
     frei0r
     libcdio
     libdavs2
     librubberband
     libvidstab
     libx264
     libx265
     libxavs
     libxavs2
     libxvid
     '
     */
    var isGPL: Bool {
      switch self {
      case .libx265, .libx264, .libaribb24:
        return true
      default:
        return false
      }
    }

    /*
     EXTERNAL_LIBRARY_VERSION3_LIST='
     gmp
     liblensfun
     libvmaf
     libvo_amrwbenc
     mbedtls
     rkmpp
     '
     */
    var isVersion3: Bool {
      switch self {
      case .libaribb24, .libopencore:
        return true
      default:
        return false
      }
    }

    static func name(for value: Ffmpeg.FFmpegDependeny) -> NameSpecification {
      .customLong("enable-\(value.rawValue)")
    }
    static func help(for value: Self) -> ArgumentHelp? {
      switch value {
      case .apple:
        return "Enable all Apple system frameworks."
      default:
        return "Enable \(value.rawValue)."
      }
    }
  }

  @Flag
  var dependencyOptions: [FFmpegDependeny] = []

  @Flag(inversion: .prefixedEnableDisable)
  var autodetect: Bool = false

  private func configureOptions(builder: Builder) throws -> [String] {
    var r = Set(configure)
    if let path = configureFile {
      r.formUnion(try String(contentsOfFile: path).components(separatedBy: .newlines))
    }

    r.insert(autodetect.configureFlag("autodetect"))
    if builder.settings.library == .statik {
      r.insert("--pkg-config-flags=--static")
    }
    // MARK: External library
    Set(dependencyOptions).forEach { dependency in
      if dependency.isNonFree {
        r.insert(true.configureFlag("nonfree"))
      }
      if dependency.isGPL {
        r.insert(true.configureFlag("gpl"))
      }
      if dependency.isVersion3 {
        r.insert(true.configureFlag("version3"))
      }
      switch dependency {
      case .libopus, .libfdkaac, .libvorbis,
           .libx264, .libx265, .libwebp, .libaribb24,
           .libass:
        r.formUnion(true.configureFlag(dependency.rawValue))
      case .libopencore:
        r.formUnion(true.configureFlag("libopencore_amrnb", "libopencore_amrwb"))
      case .apple:
        #if os(macOS)
        r.formUnion(true.configureFlag("audiotoolbox", "videotoolbox",
                                       "appkit", "avfoundation", "coreimage"))
        #else
        break
        #endif
      }
    }
    return r.sorted()
  }

  var dependencies: [Package] {
    var deps = [Package]()
    dependencyOptions.forEach { dependency in
      switch dependency {
      case .libopus:
        deps.append(Opus.new())
      case .libvorbis:
        deps.append(Vorbis.new())
      case .libfdkaac:
        deps.append(FdkAac.new())
      case .libx264:
        deps.append(x264.new())
      case .libx265:
        deps.append(x265.new())
      case .libwebp:
        deps.append(Webp.new())
      case .libaribb24:
        deps.append(Aribb24.new())
      case .libopencore:
        deps.append(Opencore.new())
      case .libass:
        deps.append(Ass.new())
      case .apple: break
      }
    }
    return deps
  }

  mutating func validate() throws {
    if let path = configureFile {
      configureFile = URL(fileURLWithPath: path).path
    }
    switch preset {
    case .allYeah:
      print("ALL YEAH!")
      dependencyOptions = FFmpegDependeny.allCases
    default:
      break
    }
  }

  enum Preset: String, ExpressibleByArgument {
    case allYeah
  }

  static var minimalDecoder: Self {
    var ff = Self.new()
    //    ff.configureFile = nil
    ff.configure = "--disable-debug --disable-muxers --disable-encoders --disable-filters --disable-hwaccels --disable-network --disable-devices --enable-audiotoolbox --enable-videotoolbox --disable-autodetect --disable-programs --disable-doc".components(separatedBy: .whitespaces)
    return ff
  }

}

/*
 EXTERNAL_AUTODETECT_LIBRARY_LIST='
 alsa
 appkit
 avfoundation
 bzlib
 coreimage
 iconv
 libxcb
 libxcb_shm
 libxcb_shape
 libxcb_xfixes
 lzma
 mediafoundation
 schannel
 sdl2
 securetransport
 sndio
 xlib
 zlib
 '
 EXTERNAL_LIBRARY_GPLV3_LIST='
 libsmbclient
 '
 EXTERNAL_LIBRARY_LIST='

 avisynth
 frei0r
 libcdio
 libdavs2
 librubberband
 libvidstab
 libx264
 libx265
 libxavs
 libxavs2
 libxvid


 decklink
 libfdk_aac
 openssl
 libtls


 gmp
 libaribb24
 liblensfun
 libopencore_amrnb
 libopencore_amrwb
 libvmaf
 libvo_amrwbenc
 mbedtls
 rkmpp


 libsmbclient

 chromaprint
 gcrypt
 gnutls
 jni
 ladspa
 libaom
 libass
 libbluray
 libbs2b
 libcaca
 libcelt
 libcodec2
 libdav1d
 libdc1394
 libdrm
 libflite
 libfontconfig
 libfreetype
 libfribidi
 libglslang
 libgme
 libgsm
 libiec61883
 libilbc
 libjack
 libklvanc
 libkvazaar
 libmodplug
 libmp3lame
 libmysofa
 libopencv
 libopenh264
 libopenjpeg
 libopenmpt
 libopus
 libpulse
 librabbitmq
 librav1e
 librsvg
 librtmp
 libshine
 libsmbclient
 libsnappy
 libsoxr
 libspeex
 libsrt
 libssh
 libtensorflow
 libtesseract
 libtheora
 libtwolame
 libv4l2
 libvorbis
 libvpx
 libwavpack
 libwebp
 libxml2
 libzimg
 libzmq
 libzvbi
 lv2
 mediacodec
 openal
 opengl
 pocketsphinx
 vapoursynth
 '
 EXTERNAL_LIBRARY_NONFREE_LIST='
 decklink
 libfdk_aac
 openssl
 libtls
 '
 EXTRALIBS_LIST='
 cpu_init
 cws2fws
 '
 FEATURE_LIST='
 ftrapv
 gray
 hardcoded_tables
 omx_rpi
 runtime_cpudetect
 safe_bitstream_reader
 shared
 small
 static
 swscale_alpha
 */
