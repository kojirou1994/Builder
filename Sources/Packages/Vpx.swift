import BuildSystem

public struct Vpx: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.13.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.arch {
    case .arm64e, .x86_64h:
      throw PackageRecipeError.unsupportedTarget
    default:
      break
    }

    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/webmproject/libvpx/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/webmproject/libvpx/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Yasm.self),
      ],
      products: [
        .library(name: "vpx", headers: ["vpx"])
      ],
      supportedLibraryType: .all
    )
  }

  /*
   Supported targets:
   arm64-android-gcc        arm64-darwin-gcc         arm64-darwin20-gcc
   arm64-linux-gcc          arm64-win64-gcc          arm64-win64-vs15
   armv7-android-gcc        armv7-darwin-gcc         armv7-linux-rvct
   armv7-linux-gcc          armv7-none-rvct          armv7-win32-gcc
   armv7-win32-vs14         armv7-win32-vs15
   armv7s-darwin-gcc
   armv8-linux-gcc
   mips32-linux-gcc
   mips64-linux-gcc
   ppc64le-linux-gcc
   sparc-solaris-gcc
   x86_64-android-gcc       x86_64-darwin9-gcc       x86_64-darwin10-gcc
   x86_64-darwin11-gcc      x86_64-darwin12-gcc      x86_64-darwin13-gcc
   x86_64-darwin14-gcc      x86_64-darwin15-gcc      x86_64-darwin16-gcc
   x86_64-darwin17-gcc      x86_64-darwin18-gcc      x86_64-darwin19-gcc
   x86_64-darwin20-gcc      x86_64-iphonesimulator-gcc x86_64-linux-gcc
   x86_64-linux-icc         x86_64-solaris-gcc       x86_64-win64-gcc
   x86_64-win64-vs14        x86_64-win64-vs15        x86_64-win64-vs16
   generic-gnu
   */

  public func build(with context: BuildContext) throws {
    // TODO: Support Linux
    var vpxArch: String {
      switch context.order.arch {
      case .arm64, .arm64e:
        return "arm64"
      case .x86_64, .x86_64h:
        return "x86_64"
      case .armv7: return "armv7"
      case .armv7s: return "armv7s"
      default:
        return context.order.arch.gnuTripleString
      }
    }

    var vpxSystem: String {
      switch context.order.system {
      case .macOS:
        return "darwin20"
      case .linuxGNU:
        return "linux"
      default:
        return "darwin"
      }
    }

    try context.launch(
      path: "configure",
      "--prefix=\(context.prefix)",
      "--target=\(vpxArch)-\(vpxSystem)-gcc",
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, "examples"),
      configureEnableFlag(context.strictMode, "unit-tests"),
      configureEnableFlag(true, "pic"),
      configureEnableFlag(true, "vp9-highbitdepth")
    )

    try context.make()

    if context.canRunTests {
      try context.make("test") // many downloads, very slow!
    }

    try context.make("install")

    try context.fixDylibsID()
  }

}
