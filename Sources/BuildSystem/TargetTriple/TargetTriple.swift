public struct TargetTriple: Hashable, CustomStringConvertible, Codable {
  public init(arch: TargetArch, system: TargetSystem) {
    self.arch = arch
    self.system = system
  }

  public let arch: TargetArch
  public let system: TargetSystem

  public var gnuTripleString: String {
    "\(arch.gnuTripleString)-\(system.vendor)-\(system.gnuTripleString)"
  }

  public var clangTripleString: String {
    "\(arch.clangTripleString)-\(system.vendor)-\(system.clangTripleString)"
  }

  public var rustTripleString: String {
    var triple = ""
    switch arch {
    case .arm64, .arm64e:
      triple += "aarch64"
    case .armv7s:
      triple += "armv7s"
    case .armv7, .armv7k, .arm64_32:
      triple += "armv7"
    case .x86_64, .x86_64h:
      triple += "x86_64"
    }
    triple += "-"
    if system.isApple {
      triple += "apple-"
    }
    switch system {
    case .linuxGNU: triple += "unknown-linux-gnu"
    case .iphoneOS: triple += "ios"
    case .iphoneSimulator: triple += "ios-sim"
    case .macCatalyst: triple += "ios-macabi"
    case .macOS: triple += "darwin"
    case .tvOS: triple += "tvos"
    case .tvSimulator: triple += "tvos"
    case .watchOS: triple += "darwin"
    case .watchSimulator: triple += "darwin"
    }
    return triple
  }
  
  public var description: String {
    "\(arch)-\(system)"
  }

  public static var native: Self {
    .init(arch: .native, system: .native)
  }

  public static let all: [Self] = {
    var r = [Self]()
    for arch in TargetArch.allCases {
      for system in TargetSystem.allCases {
        r.append(.init(arch: arch, system: system))
      }
    }
    return r
  }()

  public static let allValid: [Self] = all.filter(\.isValid)

  public var isValid: Bool {
    switch (arch, system) {
    case (.x86_64, .tvSimulator),  (.arm64, .tvSimulator), (.arm64e, .tvSimulator),
         (.arm64, .tvOS),
         (.armv7, .iphoneOS), (.armv7s, .iphoneOS), (.arm64, .iphoneOS), (.arm64e, .iphoneOS),
         (.x86_64, .iphoneSimulator), (.arm64, .iphoneSimulator), (.arm64e, .iphoneSimulator),
         (.x86_64, .macOS), (.arm64, .macOS), (.arm64e, .macOS),
         (.x86_64, .macCatalyst), (.arm64, .macCatalyst), (.arm64e, .macCatalyst),
         (.armv7k, .watchOS), (.arm64_32, .watchOS),
         (.x86_64, .watchSimulator), (.arm64, .watchSimulator),  (.arm64e, .watchSimulator):
      return true
    default:
      return false
    }
  }
}
