import ExecutableDescription

public struct MakeTool: Executable {
  public init(toolType: MakeToolType, parallelJobs: Int?, targets: [String] = []) {
    self.toolType = toolType
    self.parallelJobs = parallelJobs
    self.targets = targets
  }

  public var toolType: MakeToolType
  public var parallelJobs: Int?
  public var file: String?
  public var targets: [String]

  public static var executableName: String { fatalError() }

  public var arguments: [String] {
    var args = [String]()
    file.map { f in
      args.append("-f")
      args.append(f)
    }
    parallelJobs.map { j in
      args.append("-j\(j)")
    }
    args.append(contentsOf: targets)
    return args
  }

  public var executableName: String {
    toolType.rawValue
  }
}

public enum MakeToolType: String {
  case make
  case ninja
  case rake
}
