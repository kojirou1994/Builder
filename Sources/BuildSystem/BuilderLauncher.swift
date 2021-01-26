import Foundation
import TSCBasic

struct BuilderLauncher: ExecutableLauncher {
  func generateProcess<T>(for executable: T) throws -> Process where T : Executable {
    let launchPath = try executable.executableURL?.path ?? ExecutablePath.lookup(executable)
    let arguments = CollectionOfOne(launchPath) + executable.arguments

    if let workingDirectory = executable.currentDirectoryURL?.path {
      return .init(arguments: arguments,
                   environment: environment,
                   workingDirectory: AbsolutePath(workingDirectory),
                   outputRedirection: tsc.outputRedirection,
                   verbose: false, startNewProcessGroup: tsc.startNewProcessGroup)
    } else {
      return .init(arguments: arguments,
                   environment: environment,
                   outputRedirection: tsc.outputRedirection,
                   verbose: false, startNewProcessGroup: tsc.startNewProcessGroup)
    }
  }

  func launch<T>(executable: T, options: ExecutableLaunchOptions) throws -> LaunchResult where T : Executable {
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

  typealias Process = TSCExecutableLauncher.Process

  typealias LaunchResult = TSCExecutableLauncher.LaunchResult

  let tsc: TSCExecutableLauncher

  let dateFormatter: DateFormatter = .init()

  let environment: [String : String]

  init(environment: [String : String]) {
    tsc = .init(outputRedirection: .none)
    self.environment = environment
  }

}
