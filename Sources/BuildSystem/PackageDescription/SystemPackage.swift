public struct SystemPackage {
  public init(prefix: PackagePath, pkgConfigs: [SystemPackage.SystemPkgConfig]) {
    self.prefix = prefix
    self.pkgConfigs = pkgConfigs
  }

  public let prefix: PackagePath
  public let pkgConfigs: [SystemPkgConfig]

  public struct SystemPkgConfig {
    public init(name: String, content: String) {
      self.name = name
      self.content = content
    }

    public let name: String
    public let content: String
  }
}
