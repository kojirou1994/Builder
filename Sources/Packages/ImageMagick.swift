import BuildSystem

public struct ImageMagick: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "7.1.0-30"
  }

  enum QuantumDepth: UInt8, ExpressibleByArgument, CustomStringConvertible, CaseIterable {
    case k8 = 8
    case k16 = 16
    case k32 = 32

    var description: String { rawValue.description }
  }

  @Option(help: "Available: \(QuantumDepth.allCases.map(\.description).joined(separator: ", "))")
  var quantumDepth: QuantumDepth = .k16

  public static var name: String { "imagemagick" }

  public var tag: String {
    [
      quantumDepth != .k16 ? quantumDepth.description : "",
    ]
    .joined(separator: "_")
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://download.imagemagick.org/ImageMagick/download/releases/ImageMagick-\(version.toString()).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(PkgConfig.self),
        .runTime(Webp.self),
        .runTime(Freetype.self),
//        .runTime(JpegXL.self),
        .runTime(Openexr.self),
        .runTime(Mozjpeg.self),
        .runTime(Xz.self),
        .runTime(Fftw.self),
        .runTime(Zlib.self),
        .runTime(Zstd.self),
        .runTime(Libltdl.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
//    try context.autoreconf()

    if context.libraryType == .static {
      context.environment["PKG_CONFIG"] = "pkg-config --static"
    }

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureWithFlag(quantumDepth, "quantum-depth"),
      configureEnableFlag(true, "opencl"),
      configureEnableFlag(false, "openmp"),
      configureEnableFlag(false, "deprecated"),
      configureWithFlag(context.libraryType.buildShared, "modules"), // Modules may only be built if building shared libraries is enabled.
      configureWithFlag(true, "freetype"),
      configureWithFlag(true, "webp"),
      configureWithFlag(true, "magick-plus-plus"),
      configureWithFlag(false, "jxl"),
      configureWithFlag(false, "openexr"),
      configureWithFlag(true, "fftw")
    )

    try context.make()
    try context.make("install")
  }

}
