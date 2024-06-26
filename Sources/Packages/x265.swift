import BuildSystem
import FPExecutableLauncher

private let officialRepo = "https://bitbucket.org/multicoreware/x265_git.git"
private let chocoRepo = "https://github.com/kojirou1994/x265_choco.git"
public struct x265: Package {

  public init() {}

  @Flag(name: [.customLong("10")], inversion: .prefixedNo)
  var enable10bit: Bool = true

  @Flag(name: [.customLong("12")], inversion: .prefixedNo)
  var enable12bit: Bool = true

  public var defaultVersion: PackageVersion {
    .head
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    var source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: chocoRepo, requirement: .revision("0db4b2efadec842370d06fa7aa06832ee4c668a4"))
    case .stable(let version):
      source = .repository(url: officialRepo, requirement: .tag(version.toString(includeZeroPatch: false)))
    }

    if order.arch.isARM {
      if order.version <= "3.5" {
        source.patches += [
          .remote(url: "https://raw.githubusercontent.com/HandBrake/HandBrake/e4d9f3313c700acf9d8522aa270d96e806304693/contrib/x265/A00-darwin-Revert-Add-aarch64-support-Part-2.patch", sha256: nil),
          .remote(url: "https://raw.githubusercontent.com/HandBrake/HandBrake/e4d9f3313c700acf9d8522aa270d96e806304693/contrib/x265/A01-darwin-neon-support-for-arm64.patch", sha256: nil),
          .remote(url: "https://raw.githubusercontent.com/HandBrake/HandBrake/e4d9f3313c700acf9d8522aa270d96e806304693/contrib/x265/A02-threads-priority.patch", sha256: nil),
        ]
      } else {
        source.patches += [
          .remote(url: "https://raw.githubusercontent.com/HandBrake/HandBrake/a15f2d0ae131c417522a4b3a2455c79982a8e7f1/contrib/x265/A02-threads-priority.patch", sha256: nil),
          .remote(url: "https://raw.githubusercontent.com/HandBrake/HandBrake/a15f2d0ae131c417522a4b3a2455c79982a8e7f1/contrib/x265/A03-threads-pool-adjustments.patch", sha256: nil),
        ]
      }
    }

    if case .stable = order.version {
      source.patches += [
        .remote(url: "https://raw.githubusercontent.com/kojirou1994/patches/main/x265/0001-fix-Ctrl-C.patch", sha256: nil),
        .remote(url: "https://raw.githubusercontent.com/kojirou1994/patches/main/x265/0002-presets-and-tunes.patch", sha256: nil),
        .remote(url: "https://raw.githubusercontent.com/kojirou1994/patches/main/x265/0003-update-build-info.patch", sha256: nil),
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

    let srcDir = "../source"
    let toolType: MakeToolType = .ninja

    try replace(contentIn: "source/common/aarch64/pixel-util.S", matching: " x265_entropyStateBits", with: " _x265_entropyStateBits")

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
        cmakeOnFlag(true, "ENABLE_CLI")
      )

      try context.make(toolType: toolType)

      try context.moveItem(at: URL(fileURLWithPath: "libx265.a"), to: URL(fileURLWithPath: "libx265_main.a"))

      switch context.order.system {
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

        let fh = try FileHandle(forReadingFrom: scriptFileURL)
        try AnyExecutable(executableName: "ar", arguments: ["-M"])
          .launch(use: FPExecutableLauncher(standardInput: .fileHandle(fh), standardOutput: nil, standardError: nil))
      default: break
      }

      try context.make(toolType: .ninja, "install")
    }

    try context.autoRemoveUnneedLibraryFiles()
  }

  public var tag: String {
    [
      enable10bit ? "" : "NO_10BIT",
      enable12bit ? "" : "NO_12BIT",
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }

}
