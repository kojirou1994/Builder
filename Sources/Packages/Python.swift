import BuildSystem

public struct Python: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.10.5"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://www.python.org/ftp/python/\(version)/Python-\(version).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .optional(.custom(Python.self, requiredTime: .buildTime, excludeDependencyTree: true, target: .native), when: order.target != .native),
        .buildTool(PkgConfig.self),
        .runTime(Openssl.self),
        .runTime(Xz.self),
        .runTime(Bzip2.self),
//        .runTime(Gdbm.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    if context.isBuildingCross, context.order.system.isApple {
//      context.environment.append("yes", for: "ac_cv_file__dev_ptmx")
      try replace(contentIn: "configure", matching: """
  \t*-*-vxworks*)
  \t    ac_sys_system=VxWorks
  """, with: """
  \t*-*-darwin*)
  \t\tac_sys_system=Darwin
  """)

      try replace(contentIn: "configure", matching: """
  *-*-vxworks*)
  """, with: """
  *-*-darwin*)
  """)

      try replace(contentIn: "configure", matching: "as_fn_error $? \"readelf for the host is required for cross builds\" \"$LINENO\" 5", with: "")
    }

    try context.configure(
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(context.isBuildingNative, "optimizations"),
//      configureWithFlag(true, "lto"),
      configureEnableFlag(true, "ipv6"),
//      configureEnableFlag(true, "loadable-sqlite-extensions")
//      configureWithFlag(context.dependencyMap[Openssl.self], "openssl"),
      nil
    )

    try context.make()

//    if context.canRunTests {
//      try context.make("test")
//    }

    try context.make("install")
  }

}
