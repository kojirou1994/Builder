import BuildSystem

public struct Ffmpeg: Package {

  public init() {}

  public func build(with env: BuildEnvironment) throws {
    try env.configure(configureOptions(env: env))

    try env.make()

    try env.make("install")
  }

  public var defaultVersion: PackageVersion {
    .stable("4.4")
  }

  public var headPackageSource: PackageSource? {
    .tarball(url: "https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://ffmpeg.org/releases/ffmpeg-\(version.toString(includeZeroPatch: false)).tar.xz")
  }

  public var buildInfo: String {
    """
    Autodetect: \(autodetect)
    DisabledCompoennts: \(disabledComponents)
    """
  }

  @Option
  private var preset: Preset?

  @Flag
  var dependencyOptions: [FFmpegDependeny] = []

//  @Flag
//  var licenseOptions: [FFmpegLicense] = []

  @Flag
  var disabledComponents: [DisableComponents] = []

  @Flag(inversion: .prefixedEnableDisable)
  var autodetect: Bool = false

  private func configureOptions(env: BuildEnvironment) throws -> [String] {
    var r = Set<String>(["--cc=\(env.cc)", "--cxx=\(env.cxx)"])
    var licenses = Set<FFmpegLicense>()

    r.insert(configureEnableFlag(autodetect, "autodetect"))

    // static/shared library
    if env.libraryType == .statik {
      r.insert("--pkg-config-flags=--static")
    }
    r.formUnion([env.libraryType.staticConfigureFlag,
                 env.libraryType.sharedConfigureFlag])

    // MARK: External library
    Set(dependencyOptions).forEach { dependency in
      if dependency.isNonFree {
        licenses.insert(.nonfree)
      }
      if dependency.isGPL {
        licenses.insert(.gpl)
      }
      if dependency.isVersion3 {
        licenses.insert(.version3)
        licenses.insert(.gpl)
      }
      switch dependency {
      case .libopus, .libfdkaac, .libvorbis,
           .libx264, .libx265, .libwebp, .libaribb24,
           .libass, .libsvtav1, .librav1e, .libmp3lame, .libaom:
        r.formUnion(configureEnableFlag(true, dependency.rawValue))
      case .libsdl2:
        r.formUnion(configureEnableFlag(true, "sdl"))
      case .libopencore:
        r.formUnion(configureEnableFlag(true, "libopencore_amrnb", "libopencore_amrwb"))
      case .apple:
        if env.target.system.isApple {
          r.formUnion(configureEnableFlag(true, "audiotoolbox", "videotoolbox",
                                          "appkit", "avfoundation", "coreimage"))
        }
      }
    }

    // MARK: Licenses
    licenses.forEach { license in
      r.insert(configureEnableFlag(true, license.rawValue))
    }

    // MARK: Disabled
    disabledComponents.forEach { comp in
      r.insert(configureEnableFlag(false, comp.rawValue))
    }

    r.insert("--extra-cflags=\(env.environment[.cflags])")
    r.insert("--extra-ldflags=\(env.environment[.ldflags])")

    return r.sorted()
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    var deps = [PackageDependency]()
    dependencyOptions.forEach { dependency in
      switch dependency {
      case .libopus:
        deps.append(.init(Opus.self))
      case .libvorbis:
        deps.append(.init(Vorbis.self))
      case .libfdkaac:
        deps.append(.init(FdkAac.self))
      case .libx264:
        deps.append(.init(x264.self))
      case .libx265:
        deps.append(.init(x265.self))
      case .libwebp:
        deps.append(.init(Webp.self))
      case .libaribb24:
        deps.append(.init(Aribb24.self))
      case .libopencore:
        deps.append(.init(Opencore.self))
      case .libass:
        deps.append(.init(Ass.self))
      case .libsvtav1:
        deps.append(.init(SvtAv1.self))
      case .librav1e:
        deps.append(.init(Rav1e.self))
      case .libsdl2:
        deps.append(.init(Sdl2.self))
      case .libmp3lame:
        deps.append(.init(Lame.self))
      case .libaom:
        deps.append(.init(Aom.self))
      case .apple: break
      }
    }
    return .packages(deps)
  }

  public var tag: String {
    dependencyOptions.map(\.rawValue).sorted().joined()
      + disabledComponents.map(\.rawValue).sorted().joined()
      + (autodetect ? "autodetect" : "")
  }

  public mutating func validate() throws {
    switch preset {
    case .allYeah:
      print("FFMPEG ALL YEAH!")
      dependencyOptions = FFmpegDependeny.allCases
    default:
      break
    }
  }

  enum Preset: String, ExpressibleByArgument, CustomStringConvertible {
    case allYeah
//    case minimalDecoder

    var description: String { rawValue }
  }

  static var minimalDecoder: Self {
    var ff = Self.defaultPackage
    ff.dependencyOptions.append(.apple)
    ff.disabledComponents = [.muxers, .encoders, .filters, .hwaccels, .network, .devices, .programs, .doc]
    return ff
  }

}

extension Ffmpeg {
  enum DisableComponents: String, EnumerableFlag, CustomStringConvertible {
    // Individual component options
    case encoders
    case decoders
    case hwaccels
    case muxers
    case demuxers
    case parsers
    case protocols
    case indevs
    case outdevs
    case devices
    case filters

    /*
     Component options:
     --disable-avdevice       disable libavdevice build
     --disable-avcodec        disable libavcodec build
     --disable-avformat       disable libavformat build
     --disable-swresample     disable libswresample build
     --disable-swscale        disable libswscale build
     --disable-postproc       disable libpostproc build
     --disable-avfilter       disable libavfilter build
     --enable-avresample      enable libavresample build (deprecated) [no]
     --disable-pthreads       disable pthreads [autodetect]
     --disable-w32threads     disable Win32 threads [autodetect]
     --disable-os2threads     disable OS/2 threads [autodetect]
     --disable-network        disable network support [no]
     --disable-dct            disable DCT code
     --disable-dwt            disable DWT code
     --disable-error-resilience disable error resilience code
     --disable-lsp            disable LSP code
     --disable-lzo            disable LZO decoder code
     --disable-mdct           disable MDCT code
     --disable-rdft           disable RDFT code
     --disable-fft            disable FFT code
     --disable-faan           disable floating point AAN (I)DCT code
     --disable-pixelutils     disable pixel utils in libavutil
     */
    case network

    case programs
    case doc

    var description: String { rawValue }

    static func name(for value: Self) -> NameSpecification {
      .customLong("disable-\(value.rawValue)")
    }
  }
  enum FFmpegLicense: String, EnumerableFlag, CustomStringConvertible {
    case gpl
    case version3
    case nonfree

    var description: String { rawValue }

    static func name(for value: Self) -> NameSpecification {
      .customLong("enable-\(value.rawValue)")
    }

    static func help(for value: Self) -> ArgumentHelp? {
      switch value {
      case .gpl:
        return "allow use of GPL code, the resulting libs and binaries will be under GPL"
      case .version3:
        return "upgrade (L)GPL to version 3"
      case .nonfree:
        return "allow use of nonfree code, the resulting libs and binaries will be unredistributable"
      }
    }
  }

  enum FFmpegDependeny: String, EnumerableFlag, CustomStringConvertible {
    case libopus
    case libfdkaac = "libfdk-aac"
    case libvorbis
    case libx264
    case libx265
    case libwebp
    case libaribb24
    case libopencore
    case libass
    case libsvtav1
    case librav1e
    case libsdl2
    case libmp3lame
    case libaom

    case apple

    var description: String { rawValue }

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
      case .libx265, .libx264, .libaribb24, .libopencore:
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

    static func name(for value: Self) -> NameSpecification {
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
