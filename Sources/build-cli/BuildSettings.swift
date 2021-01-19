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

  var buildShared: Bool {
    self != .statik
  }
}

enum BuildTarget: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case arm64
  case x86_64

  var description: String { rawValue }

}
