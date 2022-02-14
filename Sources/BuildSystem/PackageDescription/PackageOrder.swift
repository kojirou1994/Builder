import Foundation
public struct PackageOrder: Codable {
  public init(version: PackageVersion, target: TargetTriple, libraryType: PackageLibraryBuildType) {
    self.version = version
    self.deployTarget = .init(target: target, systemVersion: nil)
    self.libraryType = libraryType
  }

  /// package version
  public let version: PackageVersion
  public var target: TargetTriple {
    deployTarget.target
  }


  public var arch: TargetArch {
    deployTarget.target.arch
  }

  public var system: TargetSystem {
    deployTarget.target.system
  }

  public let libraryType: PackageLibraryBuildType

  private let deployTarget: DeployTarget
}

public struct DeployTarget: Codable {
  public init(target: TargetTriple, systemVersion: Version?) {
    if let systemVersion = systemVersion {
      assert(systemVersion.patch == 0)
      assert(systemVersion.prereleaseIdentifiers.isEmpty)
      assert(systemVersion.buildMetadataIdentifiers.isEmpty)
      self.systemVersion = systemVersion
    } else {
      self.systemVersion = target.system.defaultDeployVersion
    }
    self.target = target
  }

  public let systemVersion: Version
  public let target: TargetTriple

  public var darwinVersion: Version {
    convertAppleVersionToDarwinVersion(system: target.system, version: systemVersion)
  }
}

func convertAppleVersionToDarwinVersion(system: TargetSystem, version: Version) -> Version {
  func unsupportedVersion() -> Never {
    fatalError("Invalid \(system) version: \(version)")
  }
  switch system {
  case .macOS:
    switch version {
    case "10.2"..."10.15":
      return .init(major: version.minor + 4, minor: 0, patch: 0)
    case "11"...:
      return .init(major: version.major + 9, minor: 0, patch: 0)
    default:
      unsupportedVersion()
    }
  case .macCatalyst:
    switch version {
    case "13"...:
      // start from iOS13 in macOS10.15(Catalina)
      // TODO: is this correct?
      return convertAppleVersionToDarwinVersion(system: .iphoneOS, version: version)
    default:
      unsupportedVersion()
    }
  case .iphoneOS, .iphoneSimulator, .tvOS, .tvSimulator:
    switch version {
    case "4"...:
      return .init(major: version.major + 6, minor: 0, patch: 0)
    default:
      unsupportedVersion()
    }
  case .watchOS, .watchSimulator:
    switch version {
    case "1"...:
      return .init(major: version.major + 13, minor: 0, patch: 0)
    default:
      unsupportedVersion()
    }
  case .linuxGNU:
    fatalError("linux target should never call this func (now)")
  }
}

func convertDarwinVersionToAppleVersion(system: TargetSystem, version: Version) -> Version {
  func unsupportedVersion() -> Never {
    fatalError("Invalid \(system) version: \(version)")
  }
  switch system {
  case .macOS:
    switch version {
    case "6"..."19":
      return .init(major: version.major - 4, minor: 0, patch: 0)
    case "20"...:
      return .init(major: version.major - 9, minor: 0, patch: 0)
    default:
      unsupportedVersion()
    }
  case .macCatalyst:
    switch version {
    case "19"...:
      // start from iOS13 in macOS10.15(Catalina)
      // TODO: is this correct?
      return convertDarwinVersionToAppleVersion(system: .iphoneOS, version: version)
    default:
      unsupportedVersion()
    }
  case .iphoneOS, .iphoneSimulator, .tvOS, .tvSimulator:
    switch version {
    case "9"...:
      return .init(major: version.major - 6, minor: 0, patch: 0)
    default:
      unsupportedVersion()
    }
  case .watchOS, .watchSimulator:
    switch version {
    case "14"...:
      return .init(major: version.major - 13, minor: 0, patch: 0)
    default:
      unsupportedVersion()
    }
  case .linuxGNU:
    fatalError("linux target should never call this func (now)")
  }
}

extension TargetSystem {
  public var defaultDeployVersion: Version {
    let macOSSystemVersion: Version
#if os(macOS)
    let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
    macOSSystemVersion = .init(major: numericCast(operatingSystemVersion.majorVersion), minor: numericCast(operatingSystemVersion.minorVersion), patch: 0)
#else
    macOSSystemVersion = "10.15"
#endif
    func notImplemented() -> Never {
      fatalError("NotImplemented!")
    }
    switch self {
    case .macOS:
      return macOSSystemVersion
    case .macCatalyst, .tvOS, .tvSimulator, .iphoneOS, .iphoneSimulator, .watchOS, .watchSimulator:
      return convertDarwinVersionToAppleVersion(system: self, version: convertAppleVersionToDarwinVersion(system: .macOS, version: macOSSystemVersion))
    case .linuxGNU:
      notImplemented()
    }
  }
}

/*
 clang deploy priority: -target > -mmacosx-version-min > env value
 */
