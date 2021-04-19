/*
 put encoded InstallSummary in prefix root path
 */
public struct InstallSummary {
  public let target: BuildTriple
  public let buildOn: BuildTriple = .native
  public let time: Double
}

public enum InstallReason {
  case user
  case dependency(package: String, buildTime: Bool)
}
