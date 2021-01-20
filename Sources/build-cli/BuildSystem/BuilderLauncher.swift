import Foundation

struct BuilderLauncher: ExecutableLauncher {
  func generateProcess<T>(for executable: T) throws -> Process where T : Executable {
    try swiftTSC.generateProcess(for: executable)
  }

  func launch<T>(executable: T, options: ExecutableLaunchOptions) throws -> LaunchResult where T : Executable {
    let process = try generateProcess(for: executable)
    // log arguments
    print(process.arguments)
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

  typealias Process = SwiftToolsSupportExecutableLauncher.Process

  typealias LaunchResult = SwiftToolsSupportExecutableLauncher.LaunchResult

  let swiftTSC: SwiftToolsSupportExecutableLauncher

  let dateFormatter: DateFormatter
  init() {
    swiftTSC = .init(outputRedirection: .collect)
    dateFormatter = .init()
  }

}
