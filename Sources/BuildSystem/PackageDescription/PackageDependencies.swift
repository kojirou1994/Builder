public struct PackageDependency: CustomStringConvertible {

  internal init(_ dependency: _Dependency) {
    self.dependency = dependency
  }

  enum _Dependency {
    case package(Package, options: PackageOptions)
    case other(manager: OtherPackageManager, names: [String], requireLinked: Bool)

    struct PackageOptions {
      init(requiredTime: DependencyTime,
           target: TargetTriple? = nil,
           libraryType: PackageLibraryBuildType? = nil,
           version: Range<Version>? = nil) {
        self.requiredTime = requiredTime
        self.target = target
        self.version = version
        self.libraryType = libraryType
      }

      // after target package is built, this package will be removed / ignored, not showing in dep tree
      let requiredTime: DependencyTime
      /// override the default build target, useful for building tools
      let target: TargetTriple?
      /// not working now
      let version: Range<Version>?
      let libraryType: PackageLibraryBuildType?
    }
  }

  let dependency: _Dependency

  public static func runTime<T: Package>(_ package: T.Type) -> Self {
    .init(.package(T.defaultPackage, options: .init(requiredTime: .runTime)))
  }

  public static func runTime(_ package: Package) -> Self {
    .init(.package(package, options: .init(requiredTime: .runTime)))
  }

  public static func buildTool<T: Package>(_ package: T.Type) -> Self {
    .init(.package(T.defaultPackage, options: .init(requiredTime: .buildTime, target: .native)))
  }

  public static func custom<T: Package>(
    _ type: T.Type = T.self, package: T? = nil,
    requiredTime: DependencyTime,
    target: TargetTriple? = nil,
    libraryType: PackageLibraryBuildType? = nil) -> Self {
      .init(.package(package ?? T.defaultPackage, options: .init(requiredTime: requiredTime, target: target, libraryType: libraryType)))
  }

  public static func brew(_ names: [String], requireLinked: Bool = true) -> Self {
    .init(.other(manager: .brew, names: names, requireLinked: requireLinked))
  }

  public static func cargo(_ names: [String]) -> Self {
    .init(.other(manager: .cargo, names: names, requireLinked: false))
  }

  enum OtherPackageManager: String {
    case cargo
    case brew
  }

  public var description: String {
    switch dependency {
    case let .package(package, options: _):
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
