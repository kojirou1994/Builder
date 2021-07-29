import BuildSystem

public struct x265: Package {

  public init() {}

  @Flag(name: [.customLong("10")], inversion: .prefixedNo)
  var enable10bit: Bool = true

  @Flag(name: [.customLong("12")], inversion: .prefixedNo)
  var enable12bit: Bool = true

//  public func validate() throws {
//    guard enable8bit || enable10bit || enable12bit else {
//      throw ValidationError("No enabled bit settings!")
//    }
//  }

  public var defaultVersion: PackageVersion {
    "3.5"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    var source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://bitbucket.org/multicoreware/x265_git.git", requirement: .branch("master"))
    case .stable(let version):
      source = .repository(url: "https://bitbucket.org/multicoreware/x265_git.git", requirement: .tag(version.toString(includeZeroPatch: false)))
    }

    if order.target.arch.isARM {
      source.patches += [
        .remote(url: "https://raw.githubusercontent.com/HandBrake/HandBrake/e4d9f3313c700acf9d8522aa270d96e806304693/contrib/x265/A00-darwin-Revert-Add-aarch64-support-Part-2.patch", sha256: nil),
        .remote(url: "https://raw.githubusercontent.com/HandBrake/HandBrake/e4d9f3313c700acf9d8522aa270d96e806304693/contrib/x265/A01-darwin-neon-support-for-arm64.patch", sha256: nil),
        .remote(url: "https://raw.githubusercontent.com/HandBrake/HandBrake/e4d9f3313c700acf9d8522aa270d96e806304693/contrib/x265/A02-threads-priority.patch", sha256: nil)
      ]
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .buildTool(Nasm.self),
      ],
      products: [
        .bin("x265"),
        .library(name: "CX265", libname: "x265", headerRoot: "", headers: ["x265.h", "x265_config.h"], shimedHeaders: ["x265.h"]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    // MARK: fix version string
    try replace(contentIn: "source/common/version.cpp", matching: "#define ONOS    \"[Mac OS X]\"", with: "#define ONOS    \"[macOS]\"")
    try replace(contentIn: "source/common/version.cpp", matching: """
      #if X86_64
      #define BITS
      """, with: """
                 #if X86_64 || defined(__aarch64__)
                 #define BITS
                 """)


    let srcDir = "../source"
    let toolType: MakeToolType = .ninja

    if enable12bit {
      try context.changingDirectory("12bit") { cwd in
        try context.cmake(
          toolType: toolType,
          srcDir,
          "-DHIGH_BIT_DEPTH=ON",
          "-DEXPORT_C_API=OFF",
          "-DENABLE_SHARED=OFF",
          "-DENABLE_CLI=OFF",
          "-DMAIN12=ON"
        )

        try context.make(toolType: toolType)
      }
    }

    if enable10bit {
      try context.changingDirectory("10bit") { cwd in
        try context.cmake(
          toolType: toolType,
          srcDir,
          "-DHIGH_BIT_DEPTH=ON",
          "-DENABLE_HDR10_PLUS=ON",
          "-DEXPORT_C_API=OFF",
          "-DENABLE_SHARED=OFF",
          "-DENABLE_CLI=OFF"
        )

        try context.make(toolType: toolType)
      }
    }

    try context.changingDirectory("8bit") { _ in

      var extraLib = [String]()
      if enable10bit {
        try context.moveItem(at: URL(fileURLWithPath: "../10bit/libx265.a"),
                            to: URL(fileURLWithPath: "libx265_main10.a"))
        extraLib.append("x265_main10.a")
      }
      if enable12bit {
        try context.moveItem(at: URL(fileURLWithPath: "../12bit/libx265.a"),
                            to: URL(fileURLWithPath: "libx265_main12.a"))
        extraLib.append("x265_main12.a")
      }

      try context.cmake(
        toolType: toolType,
        srcDir,
        cmakeDefineFlag(extraLib.joined(separator: ";"), "EXTRA_LIB"),
        cmakeDefineFlag("-L.", "EXTRA_LINK_FLAGS"),
        cmakeOnFlag(enable10bit, "LINKED_10BIT"),
        cmakeOnFlag(enable12bit, "LINKED_12BIT"),
        context.libraryType.sharedCmakeFlag,
        cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeOnFlag(true, "ENABLE_CLI")
      )

      try context.make(toolType: toolType)

      try context.moveItem(at: URL(fileURLWithPath: "libx265.a"), to: URL(fileURLWithPath: "libx265_main.a"))

      switch context.order.target.system {
      case .macOS, .macCatalyst:
        try context.launch(
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

      try context.make(toolType: .ninja, "install")
    }

    try context.autoRemoveUnneedLibraryFiles()
  }

  public var tag: String {
    [
//      enable8bit ? "" : "NO_8BIT",
      enable10bit ? "" : "NO_10BIT",
      enable12bit ? "" : "NO_12BIT",
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }

}
