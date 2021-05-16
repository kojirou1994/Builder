public enum TargetArch: String, CaseIterable, ExpressibleByArgument, CustomStringConvertible, Codable {
  case arm64
  case arm64e
  case armv7
  case armv7s
  case armv7k
  case arm64_32
  case x86_64
  case x86_64h

  public var gnuTripleString: String {
    switch self {
    case .arm64, .arm64e: return "aarch64"
    case .x86_64, .x86_64h: return Self.x86_64.rawValue
    case .armv7, .armv7s, .armv7k, .arm64_32: return "arm"
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

  public var is64Bits: Bool {
    switch self {
    case .arm64, .arm64e, .x86_64, .x86_64h: return true
    case .armv7, .armv7s, .armv7k, .arm64_32: return false
    }
  }

  public var isARM: Bool {
    switch self {
    case .x86_64, .x86_64h: return false
    case .armv7, .armv7s, .armv7k, .arm64_32, .arm64, .arm64e: return true
    }
  }

  public var isX86: Bool {
    switch self {
    case .x86_64, .x86_64h: return true
    case .armv7, .armv7s, .armv7k, .arm64_32, .arm64, .arm64e: return false
    }
  }

  public func canLaunch(arch: Self) -> Bool {
    switch self {
    case .x86_64h:
      switch arch {
      case .x86_64, .x86_64h:
        return true
      default:
        return false
      }
    case .x86_64:
      switch arch {
      case .x86_64:
        return true
      default:
        return false
      }
    case .arm64e:
      switch arch {
      case .arm64, .arm64e:
        return true
      default:
        return false
      }
    case .arm64:
      switch arch {
      case .arm64:
        return true
      default:
        return false
      }
    default:
      return false
    }
  }
}

// MARK: Meson
extension TargetArch {
  public var mesonCPUFamily: String {
    switch self {
    case .arm64, .arm64e: return "aarch64"
    case .x86_64, .x86_64h: return "x86_64"
    case .armv7, .armv7s, .armv7k, .arm64_32: return "arm"
    }
  }
}

extension TargetSystem {
  public var mesonSystemName: String {
    switch self {
    case .linuxGNU:
      return "linux"
    default:
      return "darwin"
    }
  }
}


extension BuildContext {
  
}
