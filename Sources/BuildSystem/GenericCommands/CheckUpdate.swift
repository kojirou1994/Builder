public struct PackageCheckUpdateCommand<T: Package>: ParsableCommand {

  public static var configuration: CommandConfiguration {
    .init(commandName: T.name,
          abstract: "",
          discussion: "")
  }

  public init() {}

  public func run() throws {
    let checker = PackageUpdateChecker()
    let newVersions = try checker.check(package: T.defaultPackage)

    checker.logger.info("All valid new versions: \(newVersions)")
  }
}
