import BuildSystem

public struct Gcc: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "11.1"
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

  public func build(with env: BuildEnvironment) throws {

    try env.inRandomDirectory { _ in
      try env.configure(
        directory: "..",
        env.libraryType.staticConfigureFlag,
        env.libraryType.sharedConfigureFlag,
        configureWithFlag(env.dependencyMap[Gmp.self], "gmp"),
        configureWithFlag(env.dependencyMap[Mpfr.self], "mpfr"),
        configureWithFlag(env.dependencyMap[Mpc.self], "mpc"),
        configureWithFlag(env.dependencyMap[Isl.self], "isl"),
        configureWithFlag("kojirou", "pkgversion"),
        configureWithFlag(env.sdkPath, "sysroot"),
        configureEnableFlag(false, "multilib"),
        configureEnableFlag(false, "bootstrap"),
        configureWithFlag(true, "system-zlib")
      )

      try env.make()
      try env.make("install")
    }
  }

}
