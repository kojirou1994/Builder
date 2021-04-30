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
    case (.x86_64, .tvSimulator), (.arm64, .tvSimulator), (.arm64e, .tvSimulator),
         (.arm64, .tvOS),
         (.arm64, .iphoneOS), (.armv7, .iphoneOS), (.armv7s, .iphoneOS), (.arm64e, .iphoneOS),
         (.x86_64, .iphoneSimulator), (.arm64, .iphoneSimulator), (.arm64e, .iphoneSimulator),
         (.x86_64, .macOS), (.arm64, .macOS), (.arm64e, .macOS),
         (.x86_64, .macCatalyst), (.arm64, .macCatalyst), (.arm64e, .macCatalyst),
         (.armv7, .watchOS),
         (.x86_64, .watchSimulator), (.arm64, .watchSimulator),  (.arm64e, .watchSimulator):
      return true
    default:
      return false
    }
  }
}
