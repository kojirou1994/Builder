import Version

extension Version: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(tolerant: value)!
  }
}

public struct PackageDependency {
  public init(_ package: Package, options: Options = .init()) {
    self.package = package
    self.options = options
  }
  public init<T: Package>(_ package: T.Type, options: Options = .init()) {
    self.package = T.defaultPackage
    self.options = options
  }

  public let package: Package
  public let options: Options

  public struct Options {
    public init(buildTimeOnly: Bool = false,
                target: BuildTriple? = nil,
                version: Range<Version>? = nil) {
      self.time = buildTimeOnly ? .buildTime : .runTime
      self.target = target
      self.version = version
    }

    // after target package is built, this package will be removed / ignored, not showing in dep tree
    public let time: DependencyTime
    /// override the default build target, useful for building tools
    public let target: BuildTriple?
    public let version: Range<Version>?
  }

}

internal enum OtherPackageManager {
  case cargo
  case brew
  case pip
}

public struct OtherPackages {

  internal let manager: OtherPackageManager
  internal let names: [String]

  public static var brewAutoConf: Self {
    .brew(["autoconf", "automake"])
  }

  public static func brew(_ names: [String]) -> Self {
    .init(manager: .brew, names: names)
  }

  public static func pip(_ names: [String]) -> Self {
    .init(manager: .pip, names: names)
  }

  public static func cargo(_ names: [String]) -> Self {
    .init(manager: .cargo, names: names)
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

  let packages: [PackageDependency]
  let otherPackages: [OtherPackages]

  public var isEmpty: Bool {
    packages.isEmpty && otherPackages.isEmpty
  }

  public static var empty: Self {
    .init(packages: [], otherPackages: [])
  }

  public static func brew(_ formulas: [String]) -> Self {
    .init(packages: [], otherPackages: [.init(manager: .brew, names: formulas)])
  }

  public static func packages(_ packages: [PackageDependency?]) -> Self {
    .init(packages: packages, otherPackages: [])
  }

  public static func packages(_ packages: PackageDependency?...) -> Self {
    .packages(packages)
  }

  public static func blend(packages: [PackageDependency?], brewFormulas: [String?]) -> Self {
    .init(packages: packages, otherPackages: [.init(manager: .brew, names: brewFormulas.compactMap {$0})])
  }

  public var description: String {
    """
     - packages: \(packages.map(\.package.name).sorted().joined(separator: ", "))
     - others: \(otherPackages)
    """
  }
}
