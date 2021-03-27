import XCTest
import Version

final class BuildCliPackageTests: XCTestCase {

  func testDefaultPackageAvailablity() {
    for package in allPackages {
      XCTAssertNoThrow(try package.parse([]))
      let defaultPackage = package.defaultPackage
      // default package's tag must be empty
      XCTAssertTrue(defaultPackage.tag.isEmpty)

      let defaultVersion = defaultPackage.defaultVersion
      let defaultSource = defaultPackage.packageSource(for: defaultVersion)
      
      XCTAssertNotNil(defaultSource, "Package \(package.name) has no default source!")
    }
  }

}
