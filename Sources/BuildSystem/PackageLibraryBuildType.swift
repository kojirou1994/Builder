public enum PackageLibraryBuildType: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case `static`
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
    self != .static
  }

  public var staticConfigureFlag: String {
    configureEnableFlag(buildStatic, "static")
  }
  public var sharedConfigureFlag: String {
    configureEnableFlag(buildShared, "shared")
  }

  public var staticCmakeFlag: String {
    cmakeOnFlag(buildStatic, "ENABLE_STATIC")
  }
  public var sharedCmakeFlag: String {
    cmakeOnFlag(buildShared, "ENABLE_SHARED")
  }
}
