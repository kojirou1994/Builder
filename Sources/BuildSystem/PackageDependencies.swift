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
  // after target package is built, this package will be removed / ignored, not showing in dep tree
  public let buildTimeOnly: Bool = false
  public let version: Range<Version>?
}

public enum ToolChain {
  case rust
}
/*
 .otherPackage(bin: "cargo-cinstall", package: .cargo("cargo-c"))
 */
public struct PackageDependencies: CustomStringConvertible {
  internal init(packages: [PackageDependency?], brewFormulas: [String]) {
    self.packages = packages.compactMap { $0 }
    self.brewFormulas = brewFormulas
  }

  let packages: [PackageDependency]
  let brewFormulas: [String]
  let toolschains: [ToolChain] = []

  public var isEmpty: Bool {
    packages.isEmpty && brewFormulas.isEmpty
  }

  public static var empty: Self {
    .init(packages: [], brewFormulas: [])
  }

  public static func brew(_ formulas: [String]) -> Self {
    .init(packages: [], brewFormulas: formulas)
  }

  public static func packages(_ packages: [PackageDependency?]) -> Self {
    .init(packages: packages, brewFormulas: [])
  }

  public static func packages(_ packages: PackageDependency?...) -> Self {
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
