import BuildSystem

public struct Gcc: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "11.3.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(
        url: "https://ftp.gnu.org/gnu/gcc/gcc-\(version.toString())/gcc-\(version.toString()).tar.xz",
        patches: [
          .remote(
            url: "https://github.com/iains/gcc-darwin-arm64/commit/20f61faaed3b335d792e38892d826054d2ac9f15.patch?full_index=1",
            sha256: "c0605179a856ca046d093c13cea4d2e024809ec2ad4bf3708543fc3d2e60504b")])
    }

    return .init(
      source: source,
      dependencies: [
        .runTime(Gmp.self),
        .runTime(Isl.self),
        .runTime(Mpc.self),
        .runTime(Mpfr.self),
        .runTime(Zlib.self),
        .runTime(Zstd.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in

      try context.launch(
        path: "../configure",
        "--prefix=\(context.prefix.root.path)",
        "--build=\(TargetTriple.native.gnuTripleString)21",
        "--host=\(context.order.target.gnuTripleString)21",
        context.libraryType.staticConfigureFlag,
        context.libraryType.sharedConfigureFlag,
        configureWithFlag(context.dependencyMap[Gmp.self], "gmp"),
        configureWithFlag(context.dependencyMap[Mpfr.self], "mpfr"),
        configureWithFlag(context.dependencyMap[Mpc.self], "mpc"),
        configureWithFlag(context.dependencyMap[Isl.self], "isl"),
        configureWithFlag(context.dependencyMap[Zstd.self], "zstd"),
        configureWithFlag("kojirou", "pkgversion"),
        configureWithFlag(context.sdkPath, "sysroot"),
        configureEnableFlag(!context.order.system.isApple, "multilib"),
        configureEnableFlag(false, "bootstrap"),
        configureWithFlag(true, "system-zlib")
      )

      try context.make()
      try context.make("install")
    }
  }

}
