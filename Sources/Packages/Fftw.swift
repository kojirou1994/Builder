import BuildSystem

public struct Fftw: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.3.10"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/FFTW/fftw3/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://fftw.org/pub/fftw/fftw-\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        //        .buildTool(Autoconf.self),
        //        .buildTool(Automake.self),
        //        .buildTool(Libtool.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    enum NumFormat: CaseIterable {
      case float
      case longDouble
      case normal

      var name: String? {
        switch self {
        case .float:
          return "float"
        case .longDouble:
          return "long-double"
        case .normal:
          return nil
        }
      }
    }

    func buildAlone(_ format: NumFormat) throws {
      var arguments: [String?] = [
        context.libraryType.staticConfigureFlag,
        context.libraryType.sharedConfigureFlag,
        configureEnableFlag(false, "fortran"),
        configureEnableFlag(true, "threads"),
      ]
      if format != .longDouble {
        arguments.append(contentsOf: configureEnableFlag(context.order.target.arch.isX86, "sse", "sse2", "avx", "avx2", "avx512"))
        arguments.append(configureEnableFlag(context.order.target.arch.isARM, "neon"))
      }
      format.name.map { arguments.append(configureEnableFlag(true, $0)) }

      try context.configure(directory: "..", arguments)

      try context.make("install")
    }

    try NumFormat.allCases.forEach { format in
      try context.inRandomDirectory { _ in
        try buildAlone(format)
      }
    }

  }

}
