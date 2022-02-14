import BuildSystem

public struct x264: Package {
  public init() {}

//  public var defaultVersion: PackageVersion {
//    .stable("3027")
//  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://code.videolan.org/videolan/x264/-/archive/stable/x264-stable.tar.bz2")
    case .stable(_):
      throw PackageRecipeError.unsupportedVersion
    }

    var deps = [PackageDependency]()
    if lsmash {
      deps.append(.runTime(Lsmash.self))
    }
    if libav {
//      deps.append(.init(Ffmpeg.minimalDecoder))
    }
    deps.append(.buildTool(Nasm.self))
    deps.append(.buildTool(GasPreprocessor.self))

    return .init(
      source: source,
      dependencies: deps
    )
  }

  public func build(with context: BuildContext) throws {

    let needGas = context.order.arch != .x86_64

    if needGas {
      context.environment["AS"] = "tools/gas-preprocessor.pl -arch \(context.order.arch.gnuTripleString) -- \(context.cc)"
    }

    try context.configure(
      configureEnableFlag(true, "cli"),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
//      configureEnableFlag(true, "lto"),
      configureEnableFlag(true, "strip"),
      configureEnableFlag(true, "pic"),
      needGas ? "--extra-asflags=\(context.environment[.cflags])" : nil,

      configureEnableFlag(false, "avs"),
      configureEnableFlag(libav, "swscale", defaultEnabled: true),
      configureEnableFlag(libav, "lavf", defaultEnabled: true),
      /* libavformat is not supported without swscale support */
      configureEnableFlag(false, "ffms"),
      configureEnableFlag(false, "gpac"),
      configureEnableFlag(lsmash, "lsmash", defaultEnabled: true)
    )

    try context.make()

    try context.make("install")
  }

  enum Mp4Support: String, ExpressibleByArgument {
    case lsmash
    case gpac
  }

  enum InputSupport: String, ExpressibleByArgument {
    case lavf
    case ffms
  }

  @Flag(inversion: .prefixedEnableDisable)
  var lsmash: Bool = false

  @Flag(inversion: .prefixedEnableDisable)
  var libav: Bool = false

  public var tag: String {
    [
      lsmash ? "LSMASH" : "",
      libav ? "LIBAV" : ""
    ].joined()
  }
}
