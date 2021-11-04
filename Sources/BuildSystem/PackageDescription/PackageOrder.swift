public struct PackageOrder: Codable {
  public init(version: PackageVersion, target: TargetTriple, libraryType: PackageLibraryBuildType) {
    self.version = version
    self.target = target
    self.libraryType = libraryType
  }

  public let version: PackageVersion
  public let target: TargetTriple
  public let libraryType: PackageLibraryBuildType
}
