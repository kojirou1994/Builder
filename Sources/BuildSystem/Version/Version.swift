public struct Version {

  public let major: UInt

  public let minor: UInt

  public let patch: UInt

  public let prereleaseIdentifiers: [String]

  public let buildMetadataIdentifiers: [String]

  @inlinable
  public init(major: UInt, minor: UInt, patch: UInt,
              prereleaseIdentifiers: [String] = [], buildMetadataIdentifiers: [String] = []) {
    self.major = major
    self.minor = minor
    self.patch = patch
    self.prereleaseIdentifiers = prereleaseIdentifiers
    self.buildMetadataIdentifiers = buildMetadataIdentifiers
  }

  public func toString(includeZeroMinor: Bool = true,
                       includeZeroPatch: Bool = true,
                       versionSeparator: String = ".",
                       numberWidth: Int? = nil,
                       includePrerelease: Bool = true,
                       includeBuildMetadata: Bool = true) -> String {
    func numberString(_ v: UInt) -> String {
      if let width = numberWidth {
        return String(format: "%0\(width)d", v)
      }
      return v.description
    }
    var str = numberString(major)
    if !(!includeZeroMinor && patch == 0 && minor == 0) {
      str += "\(versionSeparator)\(numberString(minor))"
    }
    if !(!includeZeroPatch && patch == 0) {
      str += "\(versionSeparator)\(numberString(patch))"
    }

    if includePrerelease {
      if !prereleaseIdentifiers.isEmpty {
        str += "-"
        str += prereleaseIdentifiers.joined(separator: ".")
      }
    }
    if includeBuildMetadata {
      if !buildMetadataIdentifiers.isEmpty {
        str += "+"
        str += buildMetadataIdentifiers.joined(separator: ".")
      }
    }
    return str
  }

}

extension Version: LosslessStringConvertible {

  public init?(_ description: String) {
    if description.isEmpty {
      return nil
    }
    var startIndex = description.startIndex
    if description[startIndex].lowercased() == "v" {
      description.formIndex(after: &startIndex)
    }
    var endIndex = description.endIndex
    if let metaStartIndex = description.lastIndex(of: "+") {
      buildMetadataIdentifiers = description[metaStartIndex...].dropFirst().split(separator: ".").map(String.init)
      endIndex = metaStartIndex
    } else {
      buildMetadataIdentifiers = []
    }
    if let preStartIndex = description[..<endIndex].lastIndex(of: "-") {
      prereleaseIdentifiers = description[preStartIndex..<endIndex].dropFirst().split(separator: ".").map(String.init)
      endIndex = preStartIndex
    } else {
      prereleaseIdentifiers = []
    }

    let parts = description[..<endIndex].split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false)
      .map { UInt($0) }

    guard !parts.contains(nil) else {
      return nil
    }

    switch parts.count {
    case 1:
      major = parts[0]!
      minor = 0
      patch = 0
    case 2:
      major = parts[0]!
      minor = parts[1]!
      patch = 0
    case 3:
      major = parts[0]!
      minor = parts[1]!
      patch = parts[2]!
    default:
      return nil
    }
  }

  /// Returns the lossless string representation of this semantic version.
  public var description: String {
    toString()
  }
}

extension Version: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let s = try container.decode(String.self)
    guard let v = Version(s) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid semantic version")
    }
    self = v
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}

extension Version: Hashable { }

extension Version: Comparable {

  public static func < (lhs: Version, rhs: Version) -> Bool {
    guard lhs.major == rhs.major else {
      return lhs.major < rhs.major
    }

    guard lhs.minor == rhs.minor else {
      return lhs.minor < rhs.minor
    }

    guard lhs.patch == rhs.patch else {
      return lhs.patch < rhs.patch
    }

    guard lhs.prereleaseIdentifiers.count > 0 else {
      return false // Non-prerelease lhs >= potentially prerelease rhs
    }

    guard rhs.prereleaseIdentifiers.count > 0 else {
      return true // Prerelease lhs < non-prerelease rhs
    }

    for (lhsPre, rhsPre) in zip(lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers) {
      if lhsPre == rhsPre {
        continue
      }
      switch lhsPre.localizedStandardCompare(rhsPre) {
      case .orderedAscending: return true
      case .orderedDescending: return false
      case .orderedSame: break
      }
    }

    return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
  }
}
