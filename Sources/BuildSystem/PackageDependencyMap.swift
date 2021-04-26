public struct PackageDependencyMap {
  /// requiered package dependencies, value is install prefix
  private var packageDependencies: [ObjectIdentifier: PackagePath] = .init()

  /// requiered brew formula dependencies, value is install prefix
  private var brewDependencies: [String: PackagePath] = .init()

  private var systemPackageIDs: Set<ObjectIdentifier> = .init()

  private(set) var systemPackages: [SystemPackage] = .init()

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

  mutating func add(package: Package, result: Builder.PackageBuildResult) {
    switch result {
    case .built(let prefix):
      self[package.identifier] = prefix
    case .system(let systemPackage):
      self[package.identifier] = systemPackage.prefix
      systemPackages.append(systemPackage)
      systemPackageIDs.insert(package.identifier)
    }
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
    self.systemPackages.append(contentsOf: other.systemPackages)
    self.systemPackageIDs.formUnion(other.systemPackageIDs)
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
    packageDependencies.forEach { (id, packageDependency) in
      if !systemPackageIDs.contains(id) {
        r.append(packageDependency)
      }
    }
    r.append(contentsOf: brewDependencies.values)
    return r
  }
}

extension PackageDependencyMap {
  public struct Info {
    public let path: PackagePath
  }
}
