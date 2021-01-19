struct x265: Package {
  func build(with builder: Builder) throws {
    try builder.withChangingDirectory("12bit", block: { cwd in
      try builder.launch(
        "cmake", "../source",
        "-DHIGH_BIT_DEPTH=ON",
        "-DEXPORT_C_API=OFF",
        "-DENABLE_SHARED=OFF",
        "-DENABLE_CLI=OFF",
        "-DMAIN12=ON")
      try builder.make()
    })

    try builder.withChangingDirectory("10bit", block: { cwd in
      try builder.launch(
        "cmake", "../source",
        "-DHIGH_BIT_DEPTH=ON",
        "-DENABLE_HDR10_PLUS=ON",
        "-DEXPORT_C_API=OFF",
        "-DENABLE_SHARED=OFF",
        "-DENABLE_CLI=OFF")
      try builder.make()
    })

    try builder.withChangingDirectory("8bit", block: { cwd in

      try builder.fm.linkItem(at: URL(fileURLWithPath: "../10bit/libx265.a"),
                              to: URL(fileURLWithPath: "libx265_main10.a"))
      try builder.fm.linkItem(at: URL(fileURLWithPath: "../12bit/libx265.a"),
                              to: URL(fileURLWithPath: "libx265_main12.a"))

      try builder.launch(
        "cmake", "../source",
        "-DCMAKE_INSTALL_PREFIX=\(builder.settings.prefix)",
        "-DEXTRA_LIB=x265_main10.a;x265_main12.a",
        "-DEXTRA_LINK_FLAGS=-L.",
        "-DLINKED_10BIT=ON",
        "-DLINKED_12BIT=ON",
        shared ? nil : "-DENABLE_SHARED=OFF",
        cli ? nil : "-DENABLE_CLI=OFF")
      try builder.make()

      try builder.fm.moveItem(at: URL(fileURLWithPath: "libx265.a"), to: URL(fileURLWithPath: "libx265_main.a"))

      #if os(macOS)
      try builder.launch(
        "libtool",
        "-static",
        "-o", "libx265.a",
        "libx265_main.a", "libx265_main10.a", "libx265_main12.a")
      #elseif os(Linux)
      try builder.launch(
        "ar", "cr",
        "libx265.a",
        "libx265_main.a", "libx265_main10.a",
        "libx265_main12.a")
      try builder.launch("ranlib", "libx265.a")
      #else
      fatalError("Unsupported os!")
      #endif

      try builder.make("install")
    })
  }

  var version: BuildVersion {
    .branch(repo: "https://bitbucket.org/multicoreware/x265_git.git", revision: nil)
  }
  @Flag(inversion: .prefixedEnableDisable)
  var shared: Bool = false
  @Flag(inversion: .prefixedEnableDisable)
  var cli: Bool = true

}
