fileprivate let headVersion = "HEAD"

public enum PackageVersion: LosslessStringConvertible, Equatable, Codable {

  public init?(_ description: String) {
    switch description {
    case headVersion, "head":
      self = .head
    default:
      guard let stableV = Version(description) else {
        return nil
      }
      self = .stable(stableV)
    }
  }
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    guard let v = Self(string) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "\(string) is not a valid version.")
    }
    self = v
  }

  public func encode(to encoder: Encoder) throws {
    try description.encode(to: encoder)
  }

  case stable(Version)
  case head

  public var description: String {
    switch self {
    case .head:
      return headVersion
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
    self = .stable(.init(value)!)
  }
}

extension Version: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(value)!
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
