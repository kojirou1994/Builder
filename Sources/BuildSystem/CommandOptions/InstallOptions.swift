struct InstallOptions: ParsableArguments {
  @Option(help: "Install content type, available: \(InstallContent.allCases.map(\.rawValue).joined(separator: ", "))")
  var installContent: InstallContent?

  @Option(help: "Install method, available: \(InstallMethod.allCases.map(\.rawValue).joined(separator: ", "))")
  var installMethod: InstallMethod = .link

  @Option(help: "Install level, available: \(RebuildLevel.allCases.map(\.rawValue).joined(separator: ", "))")
  var installLevel: RebuildLevel = .package

  @Option(help: "Install prefix")
  var installPrefix: String = "/usr/local"

  @Flag(help: "Install existed files")
  var forceInstall: Bool = false

  @Flag
  var uninstall: Bool = false
}

public enum InstallContent: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case all
  case bin
  case lib
  case pkgconfig

  public var description: String { rawValue }
}

public enum InstallMethod: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case link
  case copy

  public var description: String { rawValue }
}
