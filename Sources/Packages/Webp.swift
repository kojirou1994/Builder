import BuildSystem

public struct Webp: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.2.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/webmproject/libwebp/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/webmproject/libwebp/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      products: [
        .bin("cwebp"),
        .bin("dwebp"),
        .bin("img2webp"),
        .bin("webpinfo"),
        .bin("webpmux"),
        .library(name: "libwebp", headers: ["webp/decode.h", "webp/encode.h", "webp/types.h"]),
        .library(name: "libwebpdecoder", headers: ["webp/decode.h", "webp/types.h"]),
        .library(name: "libwebpdemux", headers: ["webp/decode.h", "webp/demux.h", "webp/mux_types.h", "webp/types.h"]),
        .library(name: "libwebpmux", headers: ["webp/mux_types.h", "webp/mux.h", "webp/types.h"]),
      ]
    )
  }

  /*
   WebP Configuration Summary
   --------------------------

   Shared libraries: yes
   Static libraries: no
   Threading support: yes
   libwebp: yes
   libwebpdecoder: yes
   libwebpdemux: yes
   libwebpmux: yes
   libwebpextras: yes

   Tools:
   cwebp : yes
   Input format support
   ====================
   JPEG : no
   PNG  : no
   TIFF : no
   WIC  : no
   dwebp : yes
   Output format support
   =====================
   PNG  : no
   WIC  : no
   GIF support : no
   anim_diff   : no
   gif2webp    : no
   img2webp    : yes
   webpmux     : yes
   vwebp       : no
   webpinfo    : yes
   SDL support : no
   vwebp_sdl   : no
   */
  public func build(with env: BuildEnvironment) throws {
    try env.autogen()

    try env.fixAutotoolsForDarwin()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--disable-gl",
      "--disable-sdl",
      "--disable-png",
      "--disable-jpeg",
      "--disable-tiff",
      "--disable-gif",
      "--disable-wic",
      "--enable-libwebpmux",
      "--enable-libwebpdecoder",
      "--enable-libwebpdemux",
      "--enable-libwebpextras"
    )

    try env.make()
    
    try env.make("install")
  }

}
