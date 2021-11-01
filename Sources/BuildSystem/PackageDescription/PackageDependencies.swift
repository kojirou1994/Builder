public struct PackageDependency: CustomStringConvertible {

  enum _Dependency {
    case package(Package, options: PackageOptions)
    case other(manager: OtherPackageManager, names: [String], requireLinked: Bool)

    struct PackageOptions {
      init(requiredTime: DependencyTime,
           target: TargetTriple? = nil,
           version: Range<Version>? = nil) {
        self.requiredTime = requiredTime
        self.target = target
        self.version = version
      }

      // after target package is built, this package will be removed / ignored, not showing in dep tree
      let requiredTime: DependencyTime
      /// override the default build target, useful for building tools
      let target: TargetTriple?
      /// not working now
      let version: Range<Version>?
    }
  }

  let dependency: _Dependency

  public static func runTime<T: Package>(_ package: T.Type) -> Self {
    .init(dependency: .package(T.defaultPackage, options: .init(requiredTime: .runTime)))
  }

  public static func runTime(_ package: Package) -> Self {
    .init(dependency: .package(package, options: .init(requiredTime: .runTime)))
  }

  public static func buildTool<T: Package>(_ package: T.Type) -> Self {
    .init(dependency: .package(T.defaultPackage, options: .init(requiredTime: .buildTime, target: .native)))
  }

  public static func brew(_ names: [String], requireLinked: Bool = true) -> Self {
    .init(dependency: .other(manager: .brew, names: names, requireLinked: requireLinked))
  }

  public static func cargo(_ names: [String]) -> Self {
    .init(dependency: .other(manager: .cargo, names: names, requireLinked: false))
  }

  enum OtherPackageManager: String {
    case cargo
    case brew
  }

  public var description: String {
    switch dependency {
    case let .package(package, options: options):
      return "\(package.name)-\(package.defaultVersion)-\(package.tag)"
    case let .other(manager: manager, names: names, requireLinked: _):
      return "\(manager.rawValue)-\(names)"
    }
  }
}

/*
 .otherPackage(bin: "cargo-cinstall", package: .cargo("cargo-c"))
 */

public enum RustChannel {
  case stable
  case beta
  case nightly
}
