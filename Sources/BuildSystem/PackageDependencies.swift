import Version

extension Version: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(tolerant: value)!
  }
}

public struct PackageDependency {

  private init(_ package: Package, requiredTime: DependencyTime, options: Options = .init()) {
    self.package = package
    self.requiredTime = requiredTime
    self.options = options
  }

  private init<T: Package>(_ package: T.Type, requiredTime: DependencyTime, options: Options = .init()) {
    self.package = T.defaultPackage
    self.requiredTime = requiredTime
    self.options = options
  }

  public static func runTime<T: Package>(_ package: T.Type) -> Self {
    .init(T.self, requiredTime: .runTime, options: .init())
  }

  public static func runTime(_ package: Package) -> Self {
    .init(package, requiredTime: .runTime, options: .init())
  }

  public static func buildTool<T: Package>(_ package: T.Type) -> Self {
    .init(T.self, requiredTime: .buildTime, options: .init(target: .native))
  }

  internal let package: Package
  // after target package is built, this package will be removed / ignored, not showing in dep tree
  internal let requiredTime: DependencyTime
  internal let options: Options

  internal struct Options {
    internal init(target: BuildTriple? = nil,
                version: Range<Version>? = nil) {
      self.target = target
      self.version = version
    }

    /// override the default build target, useful for building tools
    public let target: BuildTriple?
    public let version: Range<Version>?
  }

}

internal enum OtherPackageManager: String {
  case cargo
  case brew
  case pip
}

public struct OtherPackages: CustomStringConvertible {

  internal let manager: OtherPackageManager
  internal let names: [String]
  internal let requireLinked: Bool

  @available(*, deprecated, message: "bye-bye brew")
  public static var brewAutoConf: Self {
    .brew(["autoconf", "automake", "libtool"])
  }

  public static func brew(_ names: [String], requireLinked: Bool = true) -> Self {
    .init(manager: .brew, names: names, requireLinked: requireLinked)
  }

  public static func pip(_ names: [String]) -> Self {
    .init(manager: .pip, names: names, requireLinked: false)
  }

  public static func cargo(_ names: [String]) -> Self {
    .init(manager: .cargo, names: names, requireLinked: false)
  }

  public var description: String {
    "\(manager.rawValue): \(names)"
  }
}
/*
 .otherPackage(bin: "cargo-cinstall", package: .cargo("cargo-c"))
 */
public struct PackageDependencies: CustomStringConvertible {
  public init(packages: [PackageDependency?] = [], otherPackages: [OtherPackages] = []) {
    self.packages = packages.compactMap { $0 }
    self.otherPackages = otherPackages
  }

  public init(packages: PackageDependency?...) {
    self.init(packages: packages)
  }

  let packages: [PackageDependency]
  let otherPackages: [OtherPackages]

  public var isEmpty: Bool {
    packages.isEmpty && otherPackages.isEmpty
  }

  public static var empty: Self {
    .init(packages: [], otherPackages: [])
  }

  public static func brew(_ formulas: [String]) -> Self {
    .init(packages: [], otherPackages: [.init(manager: .brew, names: formulas, requireLinked: true)])
  }

  @available(*, deprecated, renamed: "PackageDependencies.init(packages:)")
  public static func packages(_ packages: [PackageDependency?]) -> Self {
    .init(packages: packages, otherPackages: [])
  }

  @available(*, deprecated, renamed: "PackageDependencies.init(packages:)")
  public static func packages(_ packages: PackageDependency?...) -> Self {
    PackageDependencies(packages: packages)
  }

  @available(*, deprecated, renamed: "PackageDependencies.init(packages:otherPackages:)")
  public static func blend(packages: [PackageDependency?], brewFormulas: [String?]) -> Self {
    .init(packages: packages, otherPackages: [.init(manager: .brew, names: brewFormulas.compactMap {$0}, requireLinked: true)])
  }

  public var description: String {
    """
     - packages: \(packages.map(\.package.name).sorted().joined(separator: ", "))
     - others: \(otherPackages)
    """
  }
}
