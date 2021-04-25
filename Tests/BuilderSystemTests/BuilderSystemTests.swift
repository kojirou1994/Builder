import XCTest
@testable import BuildSystem
import TSCUtility

final class BuilderSystemTests: XCTestCase {

  func testTriple() {
    for arch in BuildArch.allCases {
      for system in BuildTargetSystem.allCases {
        print(arch, system, BuildTriple(arch: arch, system: system).clangTripleString)
      }
    }
  }

  func testGetSDKPath() {
    let launcher = TSCExecutableLauncher(outputRedirection: .none)
    for system in BuildTargetSystem.allCases where system.isApple {
      XCTAssertNoThrow(try launcher.launch(executable: AnyExecutable(
                                            executableName: "xcrun",
                                            arguments: ["--sdk", system.sdkName, "--show-sdk-path"]),
                                           options: .init()))
    }
  }
}
