import ExecutableDescription

public enum XCFrameworkComponent {
  case framework(String)
  case library(String, header: String)
  case debugSymbol(String)
}

public struct XcodeCreateXCFramework: Executable {
  public init(output: String, components: [XCFrameworkComponent] = []) {
    self.output = output
    self.components = components
  }

  public static let executableName = "xcodebuild"

  public var output: String
  public var components: [XCFrameworkComponent]

  public var arguments: [String] {
    var v = [
      "-create-xcframework",
      "-output", output
    ]
    components.forEach { component in
      switch component {
      case .framework(let framework):
        v.append("-framework")
        v.append(framework)
      case .library(let library, header: let header):
        v.append("-library")
        v.append(library)
        v.append("-headers")
        v.append(header)
      case .debugSymbol(let debugSymbol):
        v.append("-debug-symbols")
        v.append(debugSymbol)
      }

    }

    return v
  }
}
