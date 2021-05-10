import Logging
import Foundation
import ExecutableLauncher
import URLFileManager
import Precondition
import KwiftUtility

/*
 MAGMA_LOGS/DATE-PACKAGE_NAME-RANDOM/PACKAGE_NAME/01.command.log
 */

final class ExeLoggingLauncher {
  internal init(logDirectoryURL: URL, actionLogger: Logger, environment: EnvironmentValues, redirectToStderr: Bool) {
    self.logDirectoryURL = logDirectoryURL
    self.actionLogger = actionLogger
    self.environment = environment
    self.redirectToStderr = redirectToStderr
  }

  let logDirectoryURL: URL
  let actionLogger: Logger
  var environment: EnvironmentValues
  var currentCommandNumber = 0
  /// redirect the
  let redirectToStderr: Bool

  private func logFilename(executableName: String) -> String {
    defer {
      assert(Thread.isMainThread, "aotmic")
      currentCommandNumber += 1
    }
    return "\(String(format: "%02d", currentCommandNumber)).\(executableName).log"
  }

  private func realOutput(executableName: String, _ outputRedirection: TSCExecutableLauncher.Process.OutputRedirection?) throws -> TSCExecutableLauncher.Process.OutputRedirection {
    if let v = outputRedirection {
      return v
    }
    let logFileURL = logDirectoryURL.appendingPathComponent(logFilename(executableName: executableName))
    let outputStreams = try MultipleOutputStream(stream: redirectToStderr ? .stderr : nil, files: [logFileURL])
    actionLogger.info("log file path: \(logFileURL.path)")
    return .stream(stdout: { buffer in
      outputStreams.write(buffer.utf8String)
    }, stderr: { _ in }, redirectStderr: true)
  }

  @discardableResult
  private func launch<T>(_ executable: T, outputRedirection: TSCExecutableLauncher.Process.OutputRedirection? = nil) throws -> LaunchResult where T : Executable {
    actionLogger.info("run exe: \(executable.commandLineArguments.joined(separator: " "))")

    let launcher = try BuilderLauncher(environment: environment, outputRedirection: realOutput(executableName: executable.executableName, outputRedirection))

    do {
      return try launcher.launch(executable: executable, options: .init(checkNonZeroExitCode: true))
    } catch let error as ExecutableError {
      switch error {
      case .executableNotFound(let name):
        actionLogger.error("Executable \(name) is not found! Used PATH: \(environment[.path])")
      case .invalidExecutableURL(let url):
        actionLogger.error("Used file at \(url.path) is not valid executable!")
      case .nonZeroExit(let status):
        actionLogger.error("Non zero exit code: \(status), failed command: \(executable.commandLineArguments)")
      }
      throw error
    }
  }

  public func launch(_ executableName: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableName: executableName, arguments: arguments.compactMap {$0}))
  }

  public func launch(path: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableURL: URL(fileURLWithPath: path), arguments: arguments.compactMap {$0}))
  }

  public func launchResult(_ executableName: String, _ arguments: [String?]) throws -> LaunchResult {
    try launch(AnyExecutable(executableName: executableName, arguments: arguments.compactMap {$0}), outputRedirection: .collect)
  }

  public func launchResult(path: String, _ arguments: [String?]) throws -> LaunchResult {
    try launch(AnyExecutable(executableURL: URL(fileURLWithPath: path), arguments: arguments.compactMap {$0}), outputRedirection: .collect)
  }
}
