struct Ffmpeg: Package {
  func build(with builder: Builder) throws {
    try builder.configure(configureOptions())

    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://ffmpeg.org/releases/ffmpeg-4.3.1.tar.xz")!, filename: nil)
  }

  @Option
  private var configure: [String] = []

  @Option
  private var configureFile: String?

  enum FFmpegDependeny: String, EnumerableFlag {
    case libopus
    case libfdkaac = "libfdk-aac"
    case apple
    case libvorbis

    var isNonFree: Bool {
      switch self {
      case .libfdkaac:
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

  private func configureOptions() throws -> [String] {
    var r = Set(configure)
    if let path = configureFile {
      r.formUnion(try String(contentsOfFile: path).components(separatedBy: .newlines))
    }

    // MARK: External library
    dependencyOptions.forEach { dependency in
      if dependency.isNonFree {
        r.insert(true.configureFlag("nonfree"))
      }
      switch dependency {
      case .libopus, .libfdkaac, .libvorbis:
        r.formUnion(true.configureFlag(dependency.rawValue))
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
      default: break
      }
    }
    return deps
  }

  mutating func validate() throws {
    if let path = configureFile {
      configureFile = URL(fileURLWithPath: path).path
    }
  }

  enum Preset {
    case allYeah
  }

  static var minimalDecoder: Self {
    var ff = Self.new()
    //    ff.configureFile = nil
    ff.configure = "--disable-debug --disable-muxers --disable-encoders --disable-filters --disable-hwaccels --disable-network --disable-devices --enable-audiotoolbox --enable-videotoolbox --disable-autodetect --disable-programs --disable-doc".components(separatedBy: .whitespaces)
    return ff
  }

}
