import Version

extension Version {
  public func toString(includeZeroMinor: Bool = true,
                       includeZeroPatch: Bool = true,
                       versionSeparator: String = ".",
                       numberWidth: Int? = nil,
                       includePrerelease: Bool = true,
                       includeBuildMetadata: Bool = true) -> String {
    func numberString(_ v: Int) -> String {
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

  public var nextMajor: Self {
    .init(major + 1, 0, 0)
  }

  public var nextMinor: Self {
    .init(major, minor + 1, 0)
  }

  public var nextPatch: Self {
    .init(major, minor, patch + 1)
  }
}

public enum PackageVersion: LosslessStringConvertible, Equatable, Codable {
  public init?(_ description: String) {
    self = .head
  }
  public init(from decoder: Decoder) throws {
    self = .head
  }

  public func encode(to encoder: Encoder) throws {
    try description.encode(to: encoder)
  }

  case stable(Version)
  case head

  public var description: String {
    switch self {
    case .head:
      return "HEAD"
    case .stable(let version):
      return version.description
    }
  }

  public var stableVersion: Version? {
    switch self {
    case .stable(let v):
      return v
    default:
      return nil
    }
  }
}

extension PackageVersion: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .stable(.init(tolerant: value)!)
  }
}

extension PackageVersion: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (_, .head):
      return true
    case let (.stable(lVer), .stable(rVer)):
      return lVer < rVer
    case (.head, .stable):
      return false
    }
  }
}
