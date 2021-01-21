struct BuildSettings {

  let prefix: String
  let library: PackageLib
  let cc: String = "clang"
}

enum BuildVersion {
  case branch(repo: String, revision: String?)
  case ball(url: URL, filename: String?)
}

enum PackageLib: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case statik = "static"
  case shared
  case all

  var description: String { rawValue }
  
  var buildStatic: Bool {
    self != .shared
  }

  var mesonFlag: String {
    switch self {
    case .all:
      return "both"
    default:
      return rawValue
    }
  }

  var buildShared: Bool {
    self != .statik
  }

  var staticConfigureFlag: String {
    buildStatic.configureFlag("static")
  }
  var sharedConfigureFlag: String {
    buildShared.configureFlag("shared")
  }

  var staticCmakeFlag: String {
    buildStatic.cmakeFlag("ENABLE_STATIC")
  }
  var sharedCmakeFlag: String {
    buildShared.cmakeFlag("ENABLE_SHARED")
  }
}

enum BuildTarget: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case arm64
  case x86_64

  var description: String { rawValue }

}

var sharedLibraryPathExtension: String {
  #if os(macOS)
  return "dylib"
  #elseif os(Linux)
  return "so"
  #else
  #error("Unsupported OS!")
  #endif
}

