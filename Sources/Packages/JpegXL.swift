import BuildSystem

public struct JpegXL: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.3.6"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://gitlab.com/wg1/jpeg-xl.git", requirement: .branch("master"))
    case .stable(let version):
      source = .repository(url: "https://gitlab.com/wg1/jpeg-xl.git", requirement: .branch("v\(version.toString())"))
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .runTime(Mozjpeg.self),
        .runTime(Ilmbase.self),
        .runTime(Openexr.self),
        .runTime(Giflib.self)
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try replace(contentIn: "CMakeLists.txt", matching: "find_package(Python COMPONENTS Interpreter)", with: "") // disable manpages

    try env.changingDirectory(env.randomFilename) { _ in

      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(true, "SJPEG_BUILD_EXAMPLES"),
        cmakeOnFlag(true, "JPEGXL_ENABLE_PLUGINS"),
        cmakeOnFlag(false, "BUILD_TESTING"),
        nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    }

    try env.autoRemoveUnneedLibraryFiles()
  }
}
