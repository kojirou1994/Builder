import BuildSystem

/*
 install zlib1g-dev libbz2-dev on linux
 */
public struct Python: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.11.7"
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
        .runTime(Readline.self),
//        .runTime(Mpdecimal.self), / * bug: https://github.com/python/cpython/issues/98557 */
        .runTime(Xz.self),
        .runTime(Bzip2.self),
        .runTime(Zlib.self),
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
      configureWithFlag(context.order.system.isApple, "lto"),
      configureEnableFlag(true, "ipv6"),
      configureEnableFlag(true, "loadable-sqlite-extensions"),
      "--with-system-expat",
//      "--with-system-libmpdec",
      "--with-readline=editline",
//      context.order.system.isApple ? "--enable-framework=\(context.prefix.appending("Frameworks").path)" : "--enable-shared",
      configureWithFlag(context.order.system.isApple, "dtrace"),
      configureWithFlag(context.order.system.isApple ? "ndbm" : "bdb", "dbmliborder"),
      nil
    )

    try context.make()

    try context.make("install")
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    if order.system == .linuxGNU {
      return .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [])
    }
    return nil
  }
}
