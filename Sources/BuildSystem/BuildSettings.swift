public struct BuildSettings {

  public let prefix: String
  public let library: PackageLib
  public let parallelJobs: Int = 8
  let cc: String = "clang"
}

struct PackageEnvironment {
  var version: PackageVersion
  var source: PackageSource
  var pkgConfigPath: String
  
}

public enum PackageLib: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case statik = "static"
  case shared
  case all

  public var description: String { rawValue }
  
  public var buildStatic: Bool {
    self != .shared
  }

  public var mesonFlag: String {
    switch self {
    case .all:
      return "both"
    default:
      return rawValue
    }
  }

  public var buildShared: Bool {
    self != .statik
  }

  public var staticConfigureFlag: String {
    configureFlag(buildStatic, "static")
  }
  public var sharedConfigureFlag: String {
    configureFlag(buildShared, "shared")
  }

  public var staticCmakeFlag: String {
    cmakeFlag(buildStatic, "ENABLE_STATIC")
  }
  public var sharedCmakeFlag: String {
    cmakeFlag(buildShared, "ENABLE_SHARED")
  }
}

public enum BuildTarget: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
//  case arm64
//  case x86_64
  case native

  public var description: String { rawValue }

}

public var sharedLibraryPathExtension: String {
  #if os(macOS)
  return "dylib"
  #elseif os(Linux)
  return "so"
  #else
  #error("Unsupported OS!")
  #endif
}

