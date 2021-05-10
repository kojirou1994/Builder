import ExecutableLauncher
import Foundation

public struct ExternalPackageEnvironment {
  public internal(set) var python: ExternalPackageInfo?

  var pythonExecutableURL: URL? {
    python.map { $0.path.bin.appendingPathComponent("python") }
  }

  var pipExecutableURL: URL? {
    python.map { $0.path.bin.appendingPathComponent("pip") }
  }

  public func pythonSitePackagesDirectoryURL() throws -> URL? {
    try pythonExecutableURL.map { pythonURL in
      try AnyExecutable(executableURL: pythonURL, arguments: ["-c", "import site; print(site.getsitepackages()[0])"])
        .launch(use: TSCExecutableLauncher(outputRedirection: .collect))
        .utf8Output()
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    .map { print("python site-packages: \($0)[end]"); return URL(fileURLWithPath: $0) }
  }
}

public struct ExternalPackageInfo {
  public let path: PackagePath
  public let version: String
}
