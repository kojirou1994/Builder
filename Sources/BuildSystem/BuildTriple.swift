public struct BuildTriple: Hashable, CustomStringConvertible {
  public let arch: BuildArch
  public let system: BuildTargetSystem

  public var gnuTripleString: String {
    "\(arch.gnuTripleString)-\(system.vendor)-\(system.gnuTripleString)"
  }

  public var clangTripleString: String {
    "\(arch.clangTripleString)-\(system.vendor)-\(system.clangTripleString)"
  }
  
  public var description: String {
    "\(arch)-\(system)"
  }

  public static var native: Self {
    .init(arch: .native, system: .native)
  }

  public static let all: [Self] = {
    var r = [Self]()
    for arch in BuildArch.allCases {
      for system in BuildTargetSystem.allCases {
        r.append(.init(arch: arch, system: system))
      }
    }
    return r
  }()

  public static let allValid: [Self] = all.filter(\.isValid)

  public var isValid: Bool {
    switch (arch, system) {
    case (.x86_64, .tvSimulator), (.arm64, .tvSimulator),
         (.arm64, .tvOS),
         (.arm64, .iphoneOS), (.armv7, .iphoneOS), (.armv7s, .iphoneOS), (.arm64e, .iphoneOS),
         (.x86_64, .iphoneSimulator), (.arm64, .iphoneSimulator),
         (.x86_64, .macOS), (.arm64, .macOS),
         (.x86_64, .macCatalyst), (.arm64, .macCatalyst),
         (.armv7, .watchOS),
         (.x86_64, .watchSimulator), (.arm64, .watchSimulator):
      return true
    default:
      return false
    }
  }
}

public enum BuildArch: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case arm64
  case arm64e
  case armv7
  case armv7s
  case x86_64

  public var gnuTripleString: String {
    switch self {
    case .arm64, .arm64e: return "aarch64"
    case .x86_64: return rawValue
    case .armv7, .armv7s: return "arm"
    }
  }

  public var clangTripleString: String {
    rawValue
  }

  public var description: String { rawValue }

  public static var native: Self {
    #if arch(x86_64)
    return .x86_64
    #elseif arch(arm64)
    return .arm64
    #else
    #error("Unknown arch!")
    #endif
  }

}

public enum BuildTargetSystem: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case macOS
  case macCatalyst
  case tvOS
  case tvSimulator
  case iphoneOS
  case iphoneSimulator
  case watchOS
  case watchSimulator

  case linxGNU

  public var description: String { rawValue }

  var vendor: String {
    switch self {
    case .macOS, .macCatalyst,
         .tvOS, .tvSimulator,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator:
      return "apple"
    case .linxGNU:
      return "unknown"
    }
  }

  var isSimulator: Bool {
    switch self {
    case  .tvSimulator, .iphoneSimulator,
          .watchSimulator:
      return true
    default: return false
    }
  }

  var gnuTripleString: String {
    switch self {
    case .macOS, .macCatalyst:
      return "darwin"
    case .tvOS, .tvSimulator,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator:
      return "darwin"
    case .linxGNU:
      return "linux-gnu"
    }
  }

  var clangTripleString: String {
    switch self {
    case .macOS:
      return "darwin" // macosx
    case .macCatalyst:
      return "ios13-macabi"
    case .tvOS, .tvSimulator,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator:
      return "darwin"
    case .linxGNU:
      return "linux-gnu"
    }
  }

  var minVersionClangFlag: String {
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
    case .linxGNU: fatalError()
    }
    return "-m\(name)-version-min"
  }

  var needSdkPath: Bool {
    switch self {
    case .linxGNU:
      return false
    default: return true
    }
  }

  var sdkName: String {
    switch self {
    case .macOS, .macCatalyst: return "macosx"
    case .iphoneOS: return "iphoneos"
    case .iphoneSimulator: return "iphonesimulator"
    case .tvOS: return "appletvos"
    case .tvSimulator: return "appletvsimulator"
    case .watchOS: return "watchos"
    case .watchSimulator: return "watchsimulator"

    case .linxGNU: fatalError()
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
