import XCTest
import BuildSystem
import PackagesInfo
import Packages

final class BuildCliPackageTests: XCTestCase {

  func testDefaultPackageAvailablity() {
    let allTargets = TargetTriple.all
    var allPackagesMap = [String : Package.Type]()

    for package in allPackages {
      XCTAssertNoThrow(try package.parse([]))
      let defaultPackage = package.defaultPackage
      // default package's tag must be empty
      XCTAssertTrue(defaultPackage.tag.isEmpty, "Package \(defaultPackage.name)'s default tag is not empty! The tag is: \(defaultPackage.tag)")

      let defaultVersion = defaultPackage.defaultVersion

      let firstValidTarget = allTargets.first(where: { (try? defaultPackage.recipe(for: PackageOrder(version: defaultVersion, target: $0, libraryType: .all))) != nil })
      XCTAssertNotNil(firstValidTarget,
                      "Package \(package.name) has no default recipe for any target!")

      let recipe = try! defaultPackage.recipe(for: PackageOrder(version: defaultVersion, target: firstValidTarget!, libraryType: .all))

      XCTAssertNotNil(URL(string: recipe.source.url),
                      "Invalid default source's url for package \(package.name), url: \(recipe.source.url)")

      // check package names, the package name should be case insensitive unique
      let uniqueKey = package.name.lowercased()
      if let existedPackage = allPackagesMap[uniqueKey] {
        XCTFail("duplicated package name \"\(uniqueKey)\": \(package) and \(existedPackage)")
      } else {
        allPackagesMap[uniqueKey] = package
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

  struct HelpGeneric<T: Package>: ParsableCommand {
    static var configuration: CommandConfiguration {
      .init(commandName: T.name,
            abstract: "",
            discussion: "",
            helpNames: nil
      )
    }

    @OptionGroup
    var package: T
  }

  func testDocumentGenerate() {
    print(PackageBuildCommand<Ffmpeg>.helpMessage())

    print(HelpGeneric<Ffmpeg>.helpMessage())
  }

  func testSpeed() {
    measure {
      _ = allPackages
    }
  }
}
