import XCTest
import Version
@testable import BuildSystem

final class BuildCliPackageTests: XCTestCase {

  func testDefaultPackageAvailablity() {
    var allNames = Set<String>()
    let allTargets = BuildTriple.all
    for package in allPackages {
      XCTAssertNoThrow(try package.parse([]))
      let defaultPackage = package.defaultPackage
      // default package's tag must be empty
      XCTAssertTrue(defaultPackage.tag.isEmpty, "Package \(defaultPackage.name)'s default tag is not empty! The tag is: \(defaultPackage.tag)")

      let defaultVersion = defaultPackage.defaultVersion

      let firstValidTarget = allTargets.first(where: { (try? defaultPackage.recipe(for: PackageOrder(version: defaultVersion, target: $0))) != nil })
      XCTAssertNotNil(firstValidTarget,
                      "Package \(package.name) has no default recipe for any target!")

      let recipe = try! defaultPackage.recipe(for: PackageOrder(version: defaultVersion, target: firstValidTarget!))

      XCTAssertNotNil(URL(string: recipe.source.url),
                      "Invalid default source's url for package \(package.name), url: \(recipe.source.url)")

      // check package names
      if !allNames.insert(package.name).inserted {
        XCTFail("duplicated package name: \(package.name)")
      }
    }
  }

  func testCircularDependent() {
    allPackages.forEach { packageType in
//      let package = packageType.defaultPackage
//      var dependencyNames = Set<String>()
//      package.recipe(for: )
    }
  }

}
