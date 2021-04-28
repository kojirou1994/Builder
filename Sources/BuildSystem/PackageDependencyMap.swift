public struct PackageDependencyMap {
  /// requiered package dependencies, value is install prefix
  private(set) var packageDependencies: [ObjectIdentifier: PackagePath] = .init()

  /// requiered brew formula dependencies, value is install prefix
  private(set) var brewDependencies: [String: PackagePath] = .init()

  private subscript(_ key: ObjectIdentifier) -> PackagePath? {
    get {
      packageDependencies[key]
    }
    set {
      if let existedPath = packageDependencies[key],
         let newPath = newValue {
        precondition(existedPath.root.pathComponents == newPath.root.pathComponents,
                     "Conflicted!")
      }
      packageDependencies[key] = newValue
    }
  }

  public subscript<Key: Package>(_ key: Key.Type) -> PackagePath {
    get {
      guard let path = packageDependencies[(ObjectIdentifier(Key.self))] else {
        fatalError("Required dependency \(key.name) not existed!")
      }
      return path
    }
  }

  //  let conflictHandler: () -> ()

  mutating func add(package: Package, prefix: PackagePath) {
    self[package.identifier] = prefix
  }

  private mutating func merge(_ other: [ObjectIdentifier : PackagePath]) {
    other.forEach { self[$0.key] = $0.value }
  }

  mutating func mergeBrewDependency(_ other: [String : PackagePath]) {
    other.forEach { self[$0.key] = $0.value }
  }

  mutating func merge(_ other: Self) {
    mergeBrewDependency(other.brewDependencies)
    merge(other.packageDependencies)
  }

  public internal(set) subscript(_ formula: String) -> PackagePath {
    get {
      brewDependencies[formula]!
    }
    set {
      brewDependencies[formula] = newValue
    }
  }

  /// not including the system packages
  public var allPrefixes: [PackagePath] {
    var r = [PackagePath]()
    r.append(contentsOf: packageDependencies.values)
    r.append(contentsOf: brewDependencies.values)
    return r
  }
}

extension PackageDependencyMap {
  public struct Info {
    public let path: PackagePath
  }
}
