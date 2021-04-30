public enum TargetArch: String, CaseIterable, ExpressibleByArgument, CustomStringConvertible, Codable {
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
