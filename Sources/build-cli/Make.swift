public struct Make: Executable {
  public init(targets: [String] = []) {
    self.targets = targets
  }

  public var targets: [String]

  public static var executableName: String { "make" }

  public var arguments: [String] {
    ["-j", ProcessInfo.processInfo.processorCount.description] + targets
  }
}
