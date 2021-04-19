import BuildSystem

public struct JpegXL: Package {
  public init() {}
  public var defaultVersion: PackageVersion {
    .stable("0.3.6")
  }

  public var headPackageSource: PackageSource? {
    .repository(url: "https://gitlab.com/wg1/jpeg-xl.git", requirement: .branch("master"))
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .repository(url: "https://gitlab.com/wg1/jpeg-xl.git", requirement: .branch("v\(version.toString())"))
  }

  public func build(with env: BuildEnvironment) throws {

    try replace(contentIn: "CMakeLists.txt", matching: "find_package(Python COMPONENTS Interpreter)", with: "") // disable manpages

    try env.changingDirectory(env.randomFilename, block: { _ in

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
    })

    try env.autoRemoveUnneedLibraryFiles()
  }

  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(
      .init(Mozjpeg.self),
      .init(Ilmbase.self),
      .init(Openexr.self),
      .init(Giflib.self)
    )
  }
}
