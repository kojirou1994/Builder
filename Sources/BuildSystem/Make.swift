public struct Make: Executable {
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
