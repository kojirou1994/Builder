import BuildSystem

public struct Ffmpeg: Package {

  public init() {}

  public func build(with context: BuildContext) throws {

    if dependencyOptions.contains(.iconv) {
      context.environment.append("-liconv", for: .ldflags)
    }

    if context.libraryType == .static {
      try replace(contentIn: "configure", matching: "pkg_config_default=pkg-config", with: "pkg_config_default=\"pkg-config --static\"")
    }

    try context.launch(path: "./configure", configureOptions(context: context))

    try context.make()

    try context.make("install")
  }

  public var defaultVersion: PackageVersion {
    "6.0.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    var source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2")
    case .stable(let version):
      source = .tarball(url: "https://ffmpeg.org/releases/ffmpeg-\(version.toString(includeZeroPatch: false)).tar.xz")
    }

    if noCache {
      source.patches.append(.remote(url: "https://raw.githubusercontent.com/kojirou1994/patches/main/ffmpeg/0001-disable-file-cache.patch", sha256: nil))
    }

    source.patches.append(.remote(url: "https://raw.githubusercontent.com/kojirou1994/patches/main/ffmpeg/0002-change-AV_CODEC_FLAG-priority-for-libx265.patch", sha256: nil))

    var deps: [PackageDependency] = [
      .buildTool(Nasm.self),
      .buildTool(PkgConfig.self),
      .buildTool(GasPreprocessor.self),
    ]

    switch tls {
    case .openssl:
      deps.append(.runTime(Openssl.self))
    case .none:
      break
    case .mbedtls:
      deps.append(.runTime(Mbedtls.self))
    case .system:
      break
    }

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
        switch order.system {
        case .macOS, .linuxGNU:
          deps.append(.runTime(Rav1e.self))
        default: break // maybe need xargo
        }
      case .libsdl2:
        switch order.system {
        case .macOS, .linuxGNU:
          deps.append(.runTime(Sdl2.self))
        default: break
        }
      case .libmp3lame:
        deps.append(.runTime(Lame.self))
      case .libaom:
        deps.append(.runTime(Aom.self))
      case .libdav1d:
        deps.append(.runTime(Dav1d.self))
      case .apple: break
      case .lzma:
        deps.append(.runTime(Xz.self))
      case .bzlib:
        deps.append(.runTime(Bzip2.self))
      case .iconv: break
      case .zlib:
        deps.append(.runTime(Zlib.self))
      case .libvpx:
        deps.append(.runTime(Vpx.self))
      case .libxvid:
        deps.append(.runTime(Xvid.self))
      case .libxml2:
        deps.append(.runTime(Xml2.self))
      case .gcrypt:
        deps.append(.runTime(Gcrypt.self))
      case .libkvazaar:
        deps.append(.runTime(Kvazaar.self))
      // case .vapoursynth:
      //   deps.append(.runTime(Vapoursynth.self))
      }
    }

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
  var preset: Preset?

  @Option
  private var tls: FFmpegTLS?

  @Flag
  var dependencyOptions: [FFmpegDependeny] = []

  @Flag
  var disabledComponents: [DisableComponents] = []

  @Flag(inversion: .prefixedEnableDisable)
  var autodetect: Bool = false

  @Flag
  var noCache: Bool = false

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
      r.insert("--arch=\(context.order.arch.gnuTripleString)")
//      r.insert("--target-os=darwin")
      r.insert("--as=gas-preprocessor.pl -arch \(context.order.arch.gnuTripleString) -- \(context.cc)")
    }

    r.insert(configureEnableFlag(autodetect, "autodetect"))
//    r.insert(configureEnableFlag(true, "pthreads"))
    extraVersion.map { _ = r.insert("--extra-version=\($0)") }

//    if context.order.arch.isARM {
//      r.insert(configureEnableFlag(false, "fast-unaligned"))
//    }

    r.formUnion([context.libraryType.staticConfigureFlag,
                 context.libraryType.sharedConfigureFlag])

    // MARK: External library

    switch tls {
    case .openssl:
      licenses.insert(.nonfree)
      r.formUnion(configureEnableFlag(true, "openssl"))
    case .none:
      break
    case .mbedtls:
      licenses.insert(.version3)
      licenses.insert(.gpl)
      r.formUnion(configureEnableFlag(true, "mbedtls"))
    case .system:
      if context.order.system.isApple {
        r.formUnion(configureEnableFlag(true, "securetransport"))
      } else {
        print("no system tls!")
      }
    }

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
      case
//          .libsdl2,
          .librav1e:
        switch context.order.system {
        case .macOS, .linuxGNU:
          break
        default: return // maybe need xargo
        }
      default: break
      }
      switch dependency {
      case .libopus, .libfdkaac, .libvorbis,
           .libx264, .libx265, .libwebp, .libaribb24,
           .libass, .libsvtav1, .librav1e, .libmp3lame, .libaom, .libdav1d,
           .lzma, .bzlib, .libvpx, .libxvid, .gcrypt, .libxml2, .libkvazaar,
          //  .vapoursynth,
           .iconv,
           .zlib:
        r.formUnion(configureEnableFlag(true, dependency.rawValue))
      case .libsdl2:
        r.formUnion(configureEnableFlag(true, "sdl"))
      case .libopencore:
        r.formUnion(configureEnableFlag(true, "libopencore_amrnb", "libopencore_amrwb"))
      case .apple:
        if context.order.system.isApple {
          r.formUnion(configureEnableFlag(true, "audiotoolbox", "videotoolbox",
                                          "metal",
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

    if context.order.system == .linuxGNU {
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
      #if os(Linux)
      dependencyOptions.removeAll(where: { $0 == .iconv || $0 == .libxvid })
      #endif
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
    case avdevice, avcodec, avformat, swresample, swscale, postproc, avfilter
    case programs, ffmpeg, ffplay, ffprobe
    case doc, htmlpages, manpages, podpages, txtpages
    case network

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

  enum FFmpegTLS: String, CaseIterable, CustomStringConvertible, Encodable, ExpressibleByArgument {
    case openssl
    case mbedtls
    case system
//    case gnutls
//    case gmp
//    case libtls

    var description: String { rawValue }
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
    case libdav1d
    case lzma
    case bzlib
    case iconv
    case zlib
    case libvpx
    case libxvid
    case libxml2
    case gcrypt
    case libkvazaar
    // case vapoursynth

    case apple

    var description: String { rawValue }

    /*
     decklink
     openssl
     libtls
     */
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
        return version >= "4.4"
      default:
        return true
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
     libxavs
     libxavs2
     '
     */
    var isGPL: Bool {
      switch self {
      case .libx265, .libx264, .libaribb24, .libopencore, .libxvid:
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
 libxcb
 libxcb_shm
 libxcb_shape
 libxcb_xfixes
 mediafoundation
 schannel
 sndio
 xlib
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
 libxavs
 libxavs2
 decklink
 openssl
 libtls
 gmp
 liblensfun
 libvmaf
 libvo_amrwbenc
 mbedtls
 rkmpp
 libsmbclient
 chromaprint

 gnutls
 jni
 ladspa
 libass
 libbluray
 libbs2b
 libcaca
 libcelt
 libcodec2
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
 libmodplug
 libmp3lame
 libmysofa
 libopencv
 libopenh264
 libopenjpeg
 libopenmpt
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
 libwavpack

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
