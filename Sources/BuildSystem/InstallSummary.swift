import Foundation

/*
 put encoded InstallSummary in prefix root path
 */
public struct PackageBuildSummary: Codable {
  public let order: PackageOrder
//  public let buildMachine: BuildTriple = .native
  public let startTime: Date
  public let endTime: Date
  /// built files
//  public let builtFiles: [String]
  public let reason: BuildReason
}

public enum DependencyTime {
  case runTime
  case buildTime
}

public enum BuildReason: String, Codable {
  case user
  case dependency//(package: String, time: DependencyTime)
}

public struct InstallSummary {
  public let installContent: InstallContent
  public let installedFiles: [String]
  public let installMethod: InstallMethod
}
