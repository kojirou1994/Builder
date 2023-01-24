public enum TargetSystem: String, CaseIterable, ExpressibleByArgument, CustomStringConvertible, Codable {
  case macOS
  case macCatalyst
  case tvOS
  case tvSimulator
  case iphoneOS
  case iphoneSimulator
  case watchOS
  case watchSimulator

  case linuxGNU

  public var description: String { rawValue }

  public var vendor: String {
    switch self {
    case .macOS, .macCatalyst,
         .tvOS, .tvSimulator,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator:
      return "apple"
    case .linuxGNU:
      return "unknown"
    }
  }

  public func libraryExtension(shared: Bool) -> String {
    shared ? sharedLibraryExtension : "a"
  }

  public var sharedLibraryExtension: String {
    switch self {
    case .macOS, .macCatalyst,
         .tvOS, .tvSimulator,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator:
      return "dylib"
    case .linuxGNU:
      return "so"
    }
  }

  public var isApple: Bool {
    switch self {
    case .linuxGNU: return false
    default: return true
    }
  }

  public var isSimulator: Bool {
    switch self {
    case  .tvSimulator, .iphoneSimulator,
          .watchSimulator:
      return true
    default: return false
    }
  }

  /// default cc for this system
  public var cc: String {
    switch self {
    case .macOS, .macCatalyst,
         .tvOS, .tvSimulator,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator:
      return "clang"
    case .linuxGNU:
      return "gcc"
    }
  }

  /// default cxx for this system
  public var cxx: String {
    switch self {
    case .macOS, .macCatalyst,
         .tvOS, .tvSimulator,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator:
      return "clang++"
    case .linuxGNU:
      return "g++"
    }
  }

  public var gnuTripleString: String {
    switch self {
    case .macOS, .macCatalyst:
      return "darwin"
    case .tvOS, .tvSimulator,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator:
      return "darwin"
    case .linuxGNU:
      return "linux-gnu"
    }
  }

  public var clangTripleString: String {
    switch self {
    case .macOS:
      return "darwin" // macosx
    case .macCatalyst:
      return "ios14-macabi"
    case .tvOS, .tvSimulator,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator:
      return "darwin"
    case .linuxGNU:
      return "linux-gnu"
    }
  }

  public var minVersionClangFlag: String {
    /*
     -mios-version-min=
     -mmacosx-version-min
     -mwatchsimulator-version-min=2.0
     -mwatchos-version-min=2.0
     -mappletvsimulator-version-min=
     -mappletvos-version-min=9.0
     -miphonesimulator-version-min=
     -miphoneos-version-min=
     -mwatchsimulator-version-min
     -mwatchos-version-min=
     env TVOS_DEPLOYMENT_TARGET=9.0 %clang -isysroot SDKs/MacOSX10.9.sdk -target i386-apple-darwin10  -arch x86_64 -S -o - %s | FileCheck %s
     */
    let name: String
    switch self {
    case .iphoneOS: name = "iphoneos" // ios
    case .iphoneSimulator: name = "iphonesimulator"
    case .macOS, .macCatalyst: name = "macosx"
    case .tvOS: name = "appletvos"
    case .tvSimulator: name = "appletvsimulator"
    case .watchOS: name = "watchos"
    case .watchSimulator: name = "watchsimulator"
    case .linuxGNU: fatalError()
    }
    return "-m\(name)-version-min"
  }

  public var needSdkPath: Bool {
    switch self {
    case .linuxGNU:
      return false
    default: return true
    }
  }

  public var sdkName: String {
    switch self {
    case .macOS, .macCatalyst: return "macosx"
    case .iphoneOS: return "iphoneos"
    case .iphoneSimulator: return "iphonesimulator"
    case .tvOS: return "appletvos"
    case .tvSimulator: return "appletvsimulator"
    case .watchOS: return "watchos"
    case .watchSimulator: return "watchsimulator"

    case .linuxGNU: fatalError()
    }
  }

  public static var native: Self {
    #if os(macOS)
    return .macOS
    #elseif os(Linux)
    return .linuxGNU
    #else
    #error("Unknown system!")
    #endif
  }

}
