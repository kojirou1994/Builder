import XCTest
import Version

final class BuildCliPackageTests: XCTestCase {

  func testDefaultPackageAvailablity() {
    var allNames = Set<String>()
    for package in allPackages {
      XCTAssertNoThrow(try package.parse([]))
      let defaultPackage = package.defaultPackage
      // default package's tag must be empty
      XCTAssertTrue(defaultPackage.tag.isEmpty)

      let defaultVersion = defaultPackage.defaultVersion
      let defaultSource = defaultPackage.packageSource(for: defaultVersion)
      
      XCTAssertNotNil(defaultSource, "Package \(package.name) has no default source!")
      XCTAssertNotNil(URL(string: defaultSource!.url),
                      "Invalid default source's url for package \(package.name), url: \(defaultSource!.url)")

      // check package names
      if !allNames.insert(package.name).inserted {
        XCTFail("duplicated package name: \(package.name)")
      }
    }
  }

}
