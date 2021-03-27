import XCTest
import Version

final class BuildCliPackageTests: XCTestCase {

  func testDefaultPackageAvailablity() {
    for package in packages {
      XCTAssertNoThrow(try package.parse([]))
    }
  }

}
