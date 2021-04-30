import Logging
import Precondition
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Version {
  var nextMajor: Self {
    .init(major: major + 1, minor: 0, patch: 0)
  }

  var nextMinor: Self {
    .init(major: major, minor: minor + 1, patch: 0)
  }

  var nextPatch: Self {
    .init(major: major, minor: minor, patch: patch + 1)
  }
}


public struct PackageUpdateChecker {
  let logger = Logger(label: "check-update")
  let session = URLSession(configuration: .ephemeral)

  public init() {}

  public func check(package: Package) throws -> [Version] {
    logger.info("Checking update info for package \(package.name)")
    let defaultPackage = package
    let stableVersion = try defaultPackage.defaultVersion.stableVersion.unwrap("No stable version")
    logger.info("Current version: \(stableVersion)")

    var failedVersions = Set<Version>()
    var updateVersions = Set<Version>()

    func test(versions: [Version]) -> [Version] {
      Set(versions).compactMap { version in
        if !failedVersions.contains(version),
           !updateVersions.contains(version),
           let source = try? defaultPackage.recipe(for: .init(version: .stable(version), target: .native)).source {
          logger.info("Testing version \(version)")
          switch source.requirement {
          case .repository:
            break
          case .tarball(sha256: _):
            do {
              var request = URLRequest(url: URL(string: source.url)!)
              request.httpMethod = "HEAD"
              let response = try session.syncResultTask(with: request).get()
              let statusCode = (response.response as! HTTPURLResponse).statusCode
              try preconditionOrThrow(200..<300 ~= statusCode, "status code: \(statusCode)")
              logger.info("New version: \(version)")
              updateVersions.insert(version)
              return version
            } catch {
              logger.error("\(error)")
            }
          }
        }
        failedVersions.insert(version)
        return nil
      }
    }

    var testVersions = stableVersion.testGroup
    while case let newVersions = test(versions: testVersions),
          !newVersions.isEmpty {
      testVersions = newVersions.flatMap(\.testGroup)
    }

    return updateVersions.sorted()
  }
}
