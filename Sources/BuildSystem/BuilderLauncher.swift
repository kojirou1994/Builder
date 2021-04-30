import Foundation
import TSCBasic

public struct BuilderLauncher: ExecutableLauncher {
  public func generateProcess<T>(for executable: T) throws -> Process where T : Executable {
    let launchPath = try executable.executableURL?.path ?? ExecutablePath.lookup(executable, overridePath: environment[.path])
    let arguments = CollectionOfOne(launchPath) + executable.arguments

    if let workingDirectory = executable.currentDirectoryURL?.path {
      return .init(arguments: arguments,
                   environment: environment.values,
                   workingDirectory: AbsolutePath(workingDirectory),
                   outputRedirection: tsc.outputRedirection,
                   verbose: false, startNewProcessGroup: tsc.startNewProcessGroup)
    } else {
      return .init(arguments: arguments,
                   environment: environment.values,
                   outputRedirection: tsc.outputRedirection,
                   verbose: false, startNewProcessGroup: tsc.startNewProcessGroup)
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
      throw ExecutableError.nonZeroExit(result.exitStatus)
    }
    let finishDate = Date()
    print("Time used:", finishDate.timeIntervalSince(launchDate))
    return result
  }

  public typealias Process = TSCExecutableLauncher.Process

  public typealias LaunchResult = TSCExecutableLauncher.LaunchResult

  var tsc: TSCExecutableLauncher

  public var outputRedirection: Process.OutputRedirection {
    get {
      tsc.outputRedirection
    }
    set {
      tsc = .init(outputRedirection: newValue)
    }
  }

  let dateFormatter: DateFormatter = .init()

  let environment: EnvironmentValues

  init(environment: EnvironmentValues) {
    tsc = .init(outputRedirection: .none)
    self.environment = environment
  }

}
