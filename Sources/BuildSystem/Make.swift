public struct MakeTool: Executable {
  public init(toolType: MakeToolType, parallelJobs: Int?, targets: [String] = []) {
    self.toolType = toolType
    self.parallelJobs = parallelJobs
    self.targets = targets
  }

  public var toolType: MakeToolType
  public var parallelJobs: Int?
  public var targets: [String]

  public static var executableName: String { fatalError() }

  public var arguments: [String] {
    var args = [String]()
    args.reserveCapacity(2 + targets.count)
    parallelJobs.map { j in
      args.append("-j")
      args.append(j.description)
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
}

public struct Rake: Executable {
  public init(jobs: Int, targets: [String] = []) {
    self.jobs = jobs
    self.targets = targets
  }

  public var jobs: Int
  public var targets: [String]

  public static var executableName: String { "make" }

  public var arguments: [String] {
    ["-j", jobs.description] + targets
  }
}
