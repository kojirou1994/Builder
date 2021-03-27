import Version

extension Version: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(tolerant: value)!
  }
}

public struct PackageDependency {
  public init(_ package: Package, version: Range<Version>? = nil) {
    self.package = package
    self.version = version
  }
  public init<T: Package>(_ package: T.Type, version: Range<Version>? = nil) {
    self.package = T.defaultPackage
    self.version = version
  }

  public let package: Package
  public let version: Range<Version>?
}

public struct PackageDependencies: CustomStringConvertible {
  let packages: [PackageDependency]
  let brewFormulas: [String]

  public var isEmpty: Bool {
    packages.isEmpty && brewFormulas.isEmpty
  }

  public static var empty: Self {
    .init(packages: [], brewFormulas: [])
  }

  public static func brew(_ formulas: [String]) -> Self {
    .init(packages: [], brewFormulas: formulas)
  }

  public static func packages(_ packages: [PackageDependency]) -> Self {
    .init(packages: packages, brewFormulas: [])
  }

  public static func packages(_ packages: PackageDependency...) -> Self {
    .packages(packages)
  }

  public static func blend(packages: [PackageDependency], brewFormulas: [String]) -> Self {
    .init(packages: packages, brewFormulas: brewFormulas)
  }

  public var description: String {
    """
     - packages: \(packages.map(\.package.name).sorted().joined(separator: ", "))
     - brew formulas: \(brewFormulas.sorted().joined(separator: ", "))
    """
  }
}
