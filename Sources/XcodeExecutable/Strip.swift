import ExecutableDescription

public struct Strip: Executable {
  public init(file: String) {
    self.files = [file]
  }

  public init(files: [String]) {
    self.files = files
  }

  public static let executableName = "strip"

  public let files: [String]

  public var arguments: [String] {
    files
  }
}
