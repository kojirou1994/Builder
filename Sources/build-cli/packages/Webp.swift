import BuildSystem

struct Webp: Package {
  var version: PackageVersion {
    .stable("1.1.0")
  }

  var products: [BuildProduct] {
    [
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
  }

  func build(with env: BuildEnvironment) throws {
    try env.autogen()

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

  var source: PackageSource {
    .tarball(url: "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.1.0.tar.gz")
  }

//  var dependencies: [Package] {
//    [Mozjpeg.new(), Png.new()]
//  }
}
