import BuildSystem

public struct Ffmpeg: Package {

  public init() {}

  public func build(with context: BuildContext) throws {

    try context.launch(path: "configure", configureOptions(context: context))

    try context.make()

    try context.make("install")
  }

  public var defaultVersion: PackageVersion {
    .stable("4.4")
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    var source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2")
    case .stable(let version):
      source = .tarball(url: "https://ffmpeg.org/releases/ffmpeg-\(version.toString(includeZeroPatch: false)).tar.xz")
    }

    source.patches.append(.remote(url: "https://raw.githubusercontent.com/kojirou1994/patches/main/ffmpeg/0001-disable-file-cache.patch", sha256: nil))

    var deps: [PackageDependency] = [
      .buildTool(Nasm.self),
      .buildTool(PkgConfig.self),
      .buildTool(GasPreprocessor.self),
    ]

    dependencyOptions.forEach { dependency in
      guard dependency.supportsFFmpegVersion(order.version) else {
        return
      }
      switch dependency {
      case .libopus:
        deps.append(.runTime(Opus.self))
      case .libvorbis:
        deps.append(.runTime(Vorbis.self))
      case .libfdkaac:
        deps.append(.runTime(FdkAac.self))
      case .libx264:
        deps.append(.runTime(x264.self))
      case .libx265:
        deps.append(.runTime(x265.self))
      case .libwebp:
        deps.append(.runTime(Webp.self))
      case .libaribb24:
        deps.append(.runTime(Aribb24.self))
      case .libopencore:
        deps.append(.runTime(Opencore.self))
      case .libass:
        deps.append(.runTime(Ass.self))
      case .libsvtav1:
        deps.append(.runTime(SvtAv1.self))
      case .librav1e:
        switch order.target.system {
        case .macOS, .linuxGNU:
          deps.append(.runTime(Rav1e.self))
        default: break // maybe need xargo
        }
      case .libsdl2:
        switch order.target.system {
        case .macOS, .linuxGNU:
          deps.append(.runTime(Sdl2.self))
        default: break
        }
      case .libmp3lame:
        deps.append(.runTime(Lame.self))
      case .libaom:
        deps.append(.runTime(Aom.self))
      case .apple: break
      }
    }

    /*
     libavcodec
     libavdevice
     libavfilter
     libavformat
     libavutil
     libpostproc
     libswresample
     libswscale
     */
    return .init(
      source: source,
      dependencies: deps,
      products: [
        .bin("ffmpeg"),
        .library(name: "libavcodec", libname: "avcodec", headerRoot: "libavcodec", headers: [], shimedHeaders: []),
        .library(name: "libavdevice", libname: "avdevice", headerRoot: "libavdevice", headers: [], shimedHeaders: []),
        .library(name: "libavfilter", libname: "avfilter", headerRoot: "libavfilter", headers: [], shimedHeaders: []),
        .library(name: "libavformat", libname: "avformat", headerRoot: "libavformat", headers: [], shimedHeaders: []),
        .library(name: "libavutil", libname: "avutil", headerRoot: "libavutil", headers: [], shimedHeaders: []),
        .library(name: "libpostproc", libname: "postproc", headerRoot: "libpostproc", headers: [], shimedHeaders: []),
        .library(name: "libswresample", libname: "swresample", headerRoot: "libswresample", headers: [], shimedHeaders: []),
        .library(name: "libswscale", libname: "swscale", headerRoot: "libswscale", headers: [], shimedHeaders: []),
      ]
    )
  }

  public func encode(to encoder: Encoder) throws {
    enum Keys: String, CodingKey {
      case preset, dependencyOptions, disabledComponents, autodetect
    }

    var container = encoder.container(keyedBy: Keys.self)
    try container.encode(autodetect, forKey: .autodetect)
    try container.encode(dependencyOptions, forKey: .dependencyOptions)
    try container.encode(preset, forKey: .preset)
    try container.encodeIfPresent(disabledComponents, forKey: .disabledComponents)

  }

  @Option
  private var extraVersion: String?

  @Option
  private var preset: Preset?

  @Flag
  var dependencyOptions: [FFmpegDependeny] = []

  @Flag
  var disabledComponents: [DisableComponents] = []

  @Flag(inversion: .prefixedEnableDisable)
  var autodetect: Bool = false

  private func configureOptions(context: BuildContext) throws -> [String] {
    var r = Set<String>([
      "--cc=\(context.cc)",
      "--cxx=\(context.cxx)",
      "--prefix=\(context.prefix)",
    ])
    var licenses = Set<FFmpegLicense>()
    if context.isBuildingCross {
      r.insert(configureEnableFlag(true, "cross-compile"))
      context.sdkPath.map { _ = r.insert("--sysroot=\($0)") }
      r.insert("--arch=\(context.order.target.arch.gnuTripleString)")
//      r.insert("--target-os=darwin")
      r.insert("--as=gas-preprocessor.pl -arch \(context.order.target.arch.gnuTripleString) -- \(context.cc)")
    }

    r.insert(configureEnableFlag(autodetect, "autodetect"))
//    r.insert(configureEnableFlag(true, "pthreads"))
    extraVersion.map { _ = r.insert("--extra-version=\($0)") }

    // static/shared library
    if context.libraryType == .static {
      r.insert("--pkg-config-flags=--static")
    }

    r.formUnion([context.libraryType.staticConfigureFlag,
                 context.libraryType.sharedConfigureFlag])

    // MARK: External library
    Set(dependencyOptions).forEach { dependency in
      guard dependency.supportsFFmpegVersion(context.order.version) else {
        return
      }
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
      case .libsdl2, .librav1e:
        switch context.order.target.system {
        case .macOS, .linuxGNU:
          break
        default: return // maybe need xargo
        }
      default: break
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
        if context.order.target.system.isApple {
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

    if context.order.target.system == .linuxGNU {
      r.insert("--extra-libs=-ldl -lpthread -lm -lz")
    }

    return r.sorted()
  }

  public var tag: String {
    dependencyOptions.map(\.rawValue).sorted().joined()
      + disabledComponents.map(\.rawValue).sorted().joined()
      + (autodetect ? "autodetect" : "")
      + (extraVersion ?? "")
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

  enum Preset: String, ExpressibleByArgument, CustomStringConvertible, Encodable {
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
  enum DisableComponents: String, EnumerableFlag, CustomStringConvertible, Encodable {
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

  enum FFmpegDependeny: String, EnumerableFlag, CustomStringConvertible, Encodable {
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

    func supportsFFmpegVersion(_ version: PackageVersion) -> Bool {
      switch self {
      case .libsvtav1:
        if case .stable(let stableVersion) = version {
          return stableVersion >= "4.4"
        }
      default:
        break
      }
      return true
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
