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

public enum DependencyTime {
  case runTime
  case buildTime
}

public enum BuildReason {
  case user
  case dependency(package: String, time: DependencyTime)
}

public struct InstallSummary {
  public let installContent: InstallContent
  public let installedFiles: [String]
  public let installMethod: InstallMethod
}
