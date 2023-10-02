import Foundation
import TSCBasic
import TSCExecutableLauncher
import FPExecutableLauncher

public struct BuilderLauncher: ExecutableLauncher {
  public func generateProcess<T>(for executable: T) throws -> Process where T : Executable {
    let launchPath = try ExecutablePath.lookup(executable, forcePATH: environment[.path]).get()
    let arguments = CollectionOfOne(launchPath) + executable.arguments

    if let workingDirectory = executable.changeWorkingDirectory {
      return .init(arguments: arguments,
                   environment: environment.values,
                   workingDirectory: try AbsolutePath(validating: workingDirectory),
                   outputRedirection: tsc.outputRedirection,
                   startNewProcessGroup: tsc.startNewProcessGroup)
    } else {
      return .init(arguments: arguments,
                   environment: environment.values,
                   outputRedirection: tsc.outputRedirection,
                   startNewProcessGroup: tsc.startNewProcessGroup)
    }
  }

  public func launch<T>(executable: T, options: ExecutableLaunchOptions) throws -> LaunchResult where T : Executable {
    let process = try generateProcess(for: executable)
    // log arguments
    print(process.arguments)
    print("ENV:", process.environment["PATH", default:"NO PATH"], process.environment["PKG_CONFIG_PATH", default:"NO PKG_CONFIG_PATH"])
    let launchDate = Date()
    try process.launch()
    let result = try process.waitUntilExit()
    if options.checkNonZeroExitCode, result.exitStatus != .terminated(code: 0) {
      print("FAILED CMD:", process.arguments)
      // print last xx line log
      throw ExecutableError.nonZeroExit
    }
    let finishDate = Date()
    print("Time used:", finishDate.timeIntervalSince(launchDate))
    return result
  }

  public typealias Process = TSCExecutableLauncher.Process

  public typealias LaunchResult = TSCExecutableLauncher.LaunchResult

  let tsc: TSCExecutableLauncher

  let environment: EnvironmentValues

  init(environment: EnvironmentValues, outputRedirection: TSCExecutableLauncher.Process.OutputRedirection) {
    tsc = .init(outputRedirection: outputRedirection)
    self.environment = environment
  }

}
