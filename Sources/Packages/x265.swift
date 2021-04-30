import BuildSystem

public struct x265: Package {

  public init() {}

  @Flag(name: [.customLong("10")], inversion: .prefixedNo)
  var enable10bit: Bool = true

  @Flag(name: [.customLong("12")], inversion: .prefixedNo)
  var enable12bit: Bool = true

  @Flag(inversion: .prefixedEnableDisable)
  var cli: Bool = false

//  public func validate() throws {
//    guard enable8bit || enable10bit || enable12bit else {
//      throw ValidationError("No enabled bit settings!")
//    }
//  }

  public var defaultVersion: PackageVersion {
    "3.5"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://bitbucket.org/multicoreware/x265_git.git", requirement: .branch("master"))
    case .stable(let version):
      source = .repository(url: "https://bitbucket.org/multicoreware/x265_git.git", requirement: .tag(version.toString(includeZeroPatch: false)))
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(Nasm.self)
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try replace(contentIn: "source/CMakeLists.txt", matching: "set_target_properties(x265-shared PROPERTIES MACOSX_RPATH 1)", with: "")

    let srcDir = "../source"

    /*
     set -DNASM_EXECUTABLE="" for arm64
     */
    let nasmEnabled = env.order.target.arch != .x86_64 ?
      //      cmakeDefineFlag("", "NASM_EXECUTABLE")
      cmakeDefineFlag("yasm", "CMAKE_ASM_YASM_COMPILER")
      : nil

    if enable12bit {
      try env.changingDirectory("12bit") { cwd in
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
      }
    }

    if enable10bit {
      try env.changingDirectory("10bit") { cwd in
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
      }
    }

    try env.changingDirectory("8bit") { _ in

      var extraLib = [String]()
      if enable10bit {
        try env.moveItem(at: URL(fileURLWithPath: "../10bit/libx265.a"),
                            to: URL(fileURLWithPath: "libx265_main10.a"))
        extraLib.append("x265_main10.a")
      }
      if enable12bit {
        try env.moveItem(at: URL(fileURLWithPath: "../12bit/libx265.a"),
                            to: URL(fileURLWithPath: "libx265_main12.a"))
        extraLib.append("x265_main12.a")
      }

      try env.cmake(
        toolType: .ninja,
        srcDir,
        cmakeDefineFlag(extraLib.joined(separator: ";"), "EXTRA_LIB"),
        cmakeDefineFlag("-L.", "EXTRA_LINK_FLAGS"),
        cmakeOnFlag(enable10bit, "LINKED_10BIT"),
        cmakeOnFlag(enable12bit, "LINKED_12BIT"),
        env.libraryType.sharedCmakeFlag,
        cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeOnFlag(cli, "ENABLE_CLI", defaultEnabled: true),
        nasmEnabled
      )

      try env.make(toolType: .ninja)

      try env.moveItem(at: URL(fileURLWithPath: "libx265.a"), to: URL(fileURLWithPath: "libx265_main.a"))

      switch env.order.target.system {
      case .macOS:
        try env.launch(
          "libtool",
          "-static",
          "-o", "libx265.a",
          "libx265_main.a",
          enable10bit ? "libx265_main10.a" : nil,
          enable12bit ? "libx265_main12.a" : nil
        )
      case .linuxGNU:
        let scriptFileURL = URL(fileURLWithPath: "ar_script")
        var script = [String]()
        script.append("CREATE libx265.a")
        script.append("ADDLIB libx265_main.a")
        if enable10bit {
          script.append("ADDLIB libx265_main10.a")
        }
        if enable12bit {
          script.append("ADDLIB libx265_main12.a")
        }
        script.append("SAVE")
        script.append("END")

        try script
          .joined(separator: "\n")
          .write(to: scriptFileURL, atomically: true, encoding: .utf8)

        _ = try FileHandle(forReadingFrom: scriptFileURL)
//        try AnyExecutable(executableName: "ar", arguments: ["-M"])
//          .launch(use: FPExecutableLauncher(standardInput: .fileHandle(fh), standardOutput: nil, standardError: nil))
      default: break
      }

      try env.make(toolType: .ninja, "install")
    }

    try env.autoRemoveUnneedLibraryFiles()
  }

  public var tag: String {
    [
      cli ? "ENABLE_CLI" : "",
//      enable8bit ? "" : "NO_8BIT",
      enable10bit ? "" : "NO_10BIT",
      enable12bit ? "" : "NO_12BIT",
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }

}
