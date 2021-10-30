import BuildSystem

public struct Gcc: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "11.2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/gcc/gcc-\(version.toString())/gcc-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Gmp.self),
        .runTime(Isl.self),
        .runTime(Mpc.self),
        .runTime(Mpfr.self),
        .runTime(Zlib.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in
      try context.configure(
        directory: "..",
        context.libraryType.staticConfigureFlag,
        context.libraryType.sharedConfigureFlag,
        configureWithFlag(context.dependencyMap[Gmp.self], "gmp"),
        configureWithFlag(context.dependencyMap[Mpfr.self], "mpfr"),
        configureWithFlag(context.dependencyMap[Mpc.self], "mpc"),
        configureWithFlag(context.dependencyMap[Isl.self], "isl"),
        configureWithFlag("kojirou", "pkgversion"),
        configureWithFlag(context.sdkPath, "sysroot"),
        configureEnableFlag(false, "multilib"),
        configureEnableFlag(false, "bootstrap"),
        configureWithFlag(true, "system-zlib")
      )

      try context.make()
      try context.make("install")
    }
  }

}
