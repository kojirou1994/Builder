import ExecutableLauncher

extension TargetSystem {
  func getSdkPath() throws -> String {
    try AnyExecutable(
      executableName: "xcrun",
      arguments: ["--sdk", sdkName, "--show-sdk-path"])
      .launch(use: TSCExecutableLauncher(outputRedirection: .collect))
      .utf8Output().trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
