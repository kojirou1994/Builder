import Foundation

/*
 put encoded InstallSummary in prefix root path
 */
public struct BuildSummary {
  public let target: BuildTriple
  public let buildMachine: BuildTriple = .native
  public let date: Date
  /// built files
  public let builtFiles: [String]
}

public enum BuildReason {
  case user
  case dependency(package: String, buildTime: Bool)
}

public struct InstallSummary {
  public let installContent: InstallContent
  public let installedFiles: [String]
  public let installMethod: InstallMethod
}
