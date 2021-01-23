import TSCUtility

public enum PackageVersion: CustomStringConvertible {
  case stable(String)
  case head

  public var description: String {
    switch self {
    case .head:
      return "HEAD"
    case .stable(let version):
      return "stable " + version
    }
  }

  public var stableVersion: String? {
    switch self {
    case .stable(let v):
      return v
    default:
      return nil
    }
  }
}
