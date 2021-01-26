import XCTest
@testable import BuildSystem

final class BuilderSystemTests: XCTestCase {
  func testBuildEnvironment() {
//    var env = BuildEnvironment(
//      version: .stable("1.0.0"),
//      source: .tarball(url: ""),
//      packageDependencies: .init(),
//      brewDependencies: .init(),
//      safeMode: false,
//      cc: "clang",
//      cxx: "clang++",
//      environment: ProcessInfo.processInfo.environment,
//      prefix: "/usr/local",
//      libraryType: .statik)
  }

  func testTriple() {
    for arch in BuildArch.allCases {
      for system in BuildTargetSystem.allCases {
        print(BuildTriple(arch: arch, system: system).tripleString)
      }
    }
  }

  func testGetSDKPath() {
    let launcher = TSCExecutableLauncher(outputRedirection: .none)
    for system in BuildTargetSystem.allCases {
      XCTAssertNoThrow(try launcher.launch(executable: AnyExecutable(
                                            executableName: "xcrun",
                                            arguments: ["--sdk", system.sdkName, "--show-sdk-path"]),
                                           options: .init()))
    }
  }
}
