import XCTest
@testable import BuildSystem
import TSCUtility
import ExecutableLauncher

final class BuilderSystemTests: XCTestCase {

  func testTriple() {
    for arch in TargetArch.allCases {
      for system in TargetSystem.allCases {
        print(arch, system, TargetTriple(arch: arch, system: system).clangTripleString)
      }
    }
  }

  func testGetSDKPath() {
    let launcher = TSCExecutableLauncher(outputRedirection: .none)
    for system in TargetSystem.allCases where system.isApple {
      XCTAssertNoThrow(try launcher.launch(executable: AnyExecutable(
                                            executableName: "xcrun",
                                            arguments: ["--sdk", system.sdkName, "--show-sdk-path"]),
                                           options: .init()))
    }
  }
}
