public struct PackageOrder: Codable {
  public init(version: PackageVersion, target: TargetTriple) {
    self.version = version
    self.target = target
  }

  public let version: PackageVersion
  public let target: TargetTriple
}
