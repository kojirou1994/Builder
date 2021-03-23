public struct PackageDependency: CustomStringConvertible {
  let packages: [Package]
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

  public static func packages(_ packages: [Package]) -> Self {
    .init(packages: packages, brewFormulas: [])
  }

  public static func packages(_ packages: Package...) -> Self {
    .packages(packages)
  }

  public static func blend(packages: [Package], brewFormulas: [String]) -> Self {
    .init(packages: packages, brewFormulas: brewFormulas)
  }

  public var description: String {
    """
     - packages: \(packages.map(\.name).sorted().joined(separator: ", "))
     - brew formulas: \(brewFormulas.sorted().joined(separator: ", "))
    """
  }
}
