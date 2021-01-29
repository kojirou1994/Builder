import BuildSystem

struct x265: Package {
  func build(with env: BuildEnvironment) throws {

    let srcDir = "../source"

    /*
     set -DNASM_EXECUTABLE="" for arm64
     */
    let nasmEnabled = env.target.arch != .x86_64 ?
//      cmakeDefineFlag("", "NASM_EXECUTABLE")
    cmakeDefineFlag("yasm", "CMAKE_ASM_YASM_COMPILER")
      : nil

    try env.changingDirectory("12bit", block: { cwd in
      try env.cmake(
        toolType: .ninja,
        srcDir,
        "-DHIGH_BIT_DEPTH=ON",
        "-DEXPORT_C_API=OFF",
        "-DENABLE_SHARED=OFF",
        "-DENABLE_CLI=OFF",
        "-DMAIN12=ON",
        nasmEnabled)

      try env.make(toolType: .ninja)
    })

    try env.changingDirectory("10bit", block: { cwd in
      try env.cmake(
        toolType: .ninja,
        srcDir,
        "-DHIGH_BIT_DEPTH=ON",
        "-DENABLE_HDR10_PLUS=ON",
        "-DEXPORT_C_API=OFF",
        "-DENABLE_SHARED=OFF",
        "-DENABLE_CLI=OFF",
        nasmEnabled)

      try env.make(toolType: .ninja)
    })

    try env.changingDirectory("8bit", block: { cwd in

      try env.fm.moveItem(at: URL(fileURLWithPath: "../10bit/libx265.a"),
                              to: URL(fileURLWithPath: "libx265_main10.a"))
      try env.fm.moveItem(at: URL(fileURLWithPath: "../12bit/libx265.a"),
                              to: URL(fileURLWithPath: "libx265_main12.a"))

      try env.cmake(
        toolType: .ninja,
        srcDir,
        "-DEXTRA_LIB=x265_main10.a;x265_main12.a",
        "-DEXTRA_LINK_FLAGS=-L.",
        "-DLINKED_10BIT=ON",
        "-DLINKED_12BIT=ON",
        env.libraryType.sharedCmakeFlag,
        cmakeOnFlag(cli, "ENABLE_CLI", defaultEnabled: true),
        nasmEnabled
        )

      try env.make(toolType: .ninja)

      try env.fm.moveItem(at: URL(fileURLWithPath: "libx265.a"), to: URL(fileURLWithPath: "libx265_main.a"))

      #if os(macOS)
      try env.launch(
        "libtool",
        "-static",
        "-o", "libx265.a",
        "libx265_main.a", "libx265_main10.a", "libx265_main12.a")
      #elseif os(Linux)
      try env.launch(
        "ar", "cr",
        "libx265.a",
        "libx265_main.a", "libx265_main10.a",
        "libx265_main12.a")
      try env.launch("ranlib", "libx265.a")
      #else
      #error("Unsupported OS!")
      #endif

      try env.make(toolType: .ninja, "install")
    })
  }

  var version: PackageVersion {
    .stable("3.4")
  }

  var source: PackageSource {
    .tarball(url: "https://bitbucket.org/multicoreware/x265_git/get/3.4.tar.gz")
//          filename: nil)
//    .branch(repo: "https://bitbucket.org/multicoreware/x265_git.git", revision: nil)
  }

  @Flag(inversion: .prefixedEnableDisable)
  var cli: Bool = false

  var tag: String {
    cli ? "ENABLE_CLI" : ""
  }
}
