import ExecutableDescription

public struct MakeTool: Executable {
  public init(toolType: MakeToolType, parallelJobs: Int?, targets: [String] = []) {
    self.toolType = toolType
    self.parallelJobs = parallelJobs
    self.targets = targets
  }

  public var toolType: MakeToolType
  public var parallelJobs: Int?
  public var directory: String?
  public var file: String?
  public var dryRun: Bool = false
  public var verbose: Bool = false
  public var targets: [String]

  public static var executableName: String { fatalError() }

  public var arguments: [String] {
    var args = [String]()
    directory.map { dir in
      args.append("-C")
      args.append(dir)
    }
    file.map { f in
      args.append("-f")
      args.append(f)
    }
    parallelJobs.map { j in
      args.append("-j\(j)")
    }
    if dryRun {
      args.append("-n")
    }
    if verbose {
      switch toolType {
      case .make:
        args.append("V=1")
        args.append("VERBOSE=1")
      case .ninja:
        args.append("-v")
      case .rake: break
      }
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
