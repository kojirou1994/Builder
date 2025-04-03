import BuildSystem
import FPExecutableLauncher

private let officialRepo = "https://bitbucket.org/multicoreware/x265_git.git"
// private let chocoRepo = "https://github.com/kojirou1994/x265_choco.git"
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

// https://bitbucket.org/multicoreware/x265_git/commits/b354c009a60bcd6d7fc04014e200a1ee9c45c167
// failed with cmake 4
    var source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: officialRepo, requirement: .revision("ef83e1285847952bd50c04cfe98bd521845f05db"))
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
      }
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
    if context.order.version == .head {
    // https://github.com/HandBrake/HandBrake/blob/281dbc98f0477e60dd2eb78ea86073ef7ceedd4a/contrib/x265/A01-threads-priority.patch
    try replace(contentIn: "source/common/threadpool.cpp", matching: """
#if _WIN32
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_BELOW_NORMAL);
#else
    __attribute__((unused)) int val = nice(10);
#endif

""", with: "")

// warning: https://bitbucket.org/multicoreware/x265_git/commits/5a0b22deb6d8adbce8a5d586bcee679eaf45babf

    // https://github.com/HandBrake/HandBrake/blob/281dbc98f0477e60dd2eb78ea86073ef7ceedd4a/contrib/x265/A02-threads-pool-adjustments.patch
    try replace(contentIn: "source/common/threadpool.cpp", matching: """
        p->frameNumThreads = 4; 
    else if (cpuCount >= 8)
#if _WIN32 && X265_ARCH_ARM64
        p->frameNumThreads = cpuCount;
#else
        p->frameNumThreads = 3;
#endif
""", with: """
#if MACOS && X265_ARCH_ARM64
        p->frameNumThreads = 16;
#else
        p->frameNumThreads = 4;
#endif
    else if (cpuCount >= 8)
#if MACOS && X265_ARCH_ARM64
        p->frameNumThreads = 8;
#elif _WIN32 && X265_ARCH_ARM64
        p->frameNumThreads = cpuCount;
#else
        p->frameNumThreads = 3;
#endif
""")

    // https://github.com/HandBrake/HandBrake/blob/281dbc98f0477e60dd2eb78ea86073ef7ceedd4a/contrib/x265/A03-sei-length-crash-fix.patch
//     try replace(contentIn: "source/encoder/encoder.cpp", matching: "input = pic_in->userSEI.payloads[i];", with: """
// input = pic_in->userSEI.payloads[i];

//             if (frame->m_userSEI.payloads[i].payload && (frame->m_userSEI.payloads[i].payloadSize < input.payloadSize))
//             {
//                 delete[] frame->m_userSEI.payloads[i].payload;
//                 frame->m_userSEI.payloads[i].payload = NULL;
//             }
// """)

    // https://raw.githubusercontent.com/kojirou1994/patches/main/x265/0003-update-build-info.patch
    try replace(contentIn: "source/common/version.cpp", matching: "[clang", with: "[Clang")
    try replace(contentIn: "source/common/version.cpp", matching: "#define ONOS    \"[Mac OS X]\"", with: """
#define ONOS    "[macOS]"
#if X86_64
#define MAC_ARCH    "[Intel]"
#elif defined(__aarch64__)
#define MAC_ARCH    "[Apple Silicon]"
#endif // MAC_ARCH end 
""")
    if context.order.system.isApple {
      try replace(contentIn: "source/common/version.cpp", matching: "ONOS COMPILEDBY", with: "ONOS MAC_ARCH COMPILEDBY")
    }

    // https://raw.githubusercontent.com/kojirou1994/patches/main/x265/0002-presets-and-tunes.patch
    try replace(contentIn: "source/common/param.cpp", matching: """
            else if (!strcmp(preset, "superfast"))
            {
    """, with: """
            else if (!strncmp(preset, "flyabc", 6))
            {
                param->keyframeMin = 5;
                param->scenecutThreshold = 50;
                param->bOpenGOP = false;
                param->lookaheadDepth = 60;
                param->lookaheadSlices = 0;
                param->searchMethod = X265_HEX_SEARCH;
                param->subpelRefine = 2;
                param->searchRange = 57;
                param->maxNumReferences = 3;
                param->maxNumMergeCand = 3;
                param->bEnableStrongIntraSmoothing = false;
                param->bEnableSAO = false;
                param->selectiveSAO = false;
                param->deblockingFilterTCOffset = -3;
                param->deblockingFilterBetaOffset = -3;
                param->bEnableLoopFilter = true;
                param->maxCUSize = 32;
                param->rdoqLevel = 2;
                param->psyRdoq = 1.0;
                param->recursionSkipMode = 2;
    
                if (!strcmp(preset, "flyabc+"))
                {
                    param->bEnableEarlySkip = 0;
                }
            }
            else if (!strcmp(preset, "superfast"))
            {
    """)
    try replace(contentIn: "source/common/param.cpp", matching: "param->bframes = (param->bframes + 2) >= param->lookaheadDepth? param->bframes : param->bframes + 2;", with: "if (param->bframes + 1 < param->lookaheadDepth) param->bframes++; if (param->bframes + 1 < param->lookaheadDepth) param->bframes++;")
    try replace(contentIn: "source/common/param.cpp", matching: """
             else if (!strcmp(tune, "animation"))
    """, with: """
            else if (!strncmp(tune, "littlepox", 9) || !strncmp(tune, "vcb-s", 5)) {
                param->searchRange = 25; //down from 57
                param->bEnableAMP = 0;
                param->bEnableRectInter = 0;
                param->rc.aqStrength = 0.8; //down from 1.0
                if (param->rdLevel < 4) param->rdLevel = 4;
                param->rdoqLevel = 2; //force rdoq to be effective
                param->bEnableSAO = 0;
                param->bEnableStrongIntraSmoothing = 0;
                if (param->bframes + 1 < param->lookaheadDepth) param->bframes++;
                if (param->bframes + 1 < param->lookaheadDepth) param->bframes++; //from tune animation
                if (param->tuQTMaxInterDepth > 3) param->tuQTMaxInterDepth--;
                if (param->tuQTMaxIntraDepth > 3) param->tuQTMaxIntraDepth--;
                if (param->maxNumMergeCand > 3) param->maxNumMergeCand--;
                if (param->subpelRefine < 3) param->subpelRefine = 3;
                param->keyframeMin = 1;
                param->keyframeMax = 360;
                param->bOpenGOP = 0;
                param->deblockingFilterBetaOffset = -1;
                param->deblockingFilterTCOffset = -1;
                param->maxCUSize = 32;
                param->maxTUSize = 32;
                param->rc.qgSize = 8;
                param->cbQpOffset = -2; //better chroma quality to compensate 420 subsampling
                param->crQpOffset = -2; //better chroma quality to compensate 420 subsampling
                param->rc.pbFactor = 1.2; //down from 1.3
                param->bEnableWeightedBiPred = 1;
                if (tune[0] == 'l') {
                    // Mid bitrate anime
                    param->rc.rfConstant = 20;
                    param->psyRd = 1.5; //down
                    param->psyRdoq = 0.8; //down
        
                    if (strstr(tune, "+")) {
                        if (param->maxNumReferences < 2) param->maxNumReferences = 2;
                        if (param->subpelRefine < 3) param->subpelRefine = 3;
                        if (param->lookaheadDepth < 60) param->lookaheadDepth = 60;
                        param->searchRange = 38; //down from 57
                    }
                } else {
                    // High bitrate anime (bluray) or film
                    param->rc.rfConstant = 18;
                    param->psyRd = 1.8; //down
                    param->psyRdoq = 1.0; //same
        
                    if (strstr(tune, "+")) {
                        if (param->maxNumReferences < 3) param->maxNumReferences = 3;
                        if (param->subpelRefine < 3) param->subpelRefine = 3;
                        param->bIntraInBFrames = 1;
                        param->bEnableRectInter = 1;
                        param->limitTU = 4;
                        if (param->lookaheadDepth < 60) param->lookaheadDepth = 60;
                        param->searchRange = 38; //down from 57
                    }
                }
             }
             else if (!strcmp(tune, "animation"))
    """)

    try replace(contentIn: "source/x265.h", matching: """
    "animation", 0
    """, with: """
    "animation", "littlepox", "littlepox+", "vcb-s", "vcb-s+", 0
    """)
    try replace(contentIn: "source/x265.h", matching: """
    "placebo", 0
    """, with: """
    "placebo", "flyabc", "flyabc+", 0
    """)
    try replace(contentIn: "source/x265cli.cpp", matching: """
        H0("-t/--tune <string>               Tune the settings for a particular type of source or situation:\n");
""", with: """
        H0("           (good for everything) flyabc, (slower) flyabc+\n");
        H0("-t/--tune <string>               Tune the settings for a particular type of source or situation:\n");
        H0("             (mid bitrate anime) littlepox, (slower) littlepox+\n");
        H0("  (high bitrate anime BD / film) vcb-s,   (slower) vcb-s+\n");
""")
    try replace(contentIn: "source/x265cli.cpp", matching: "startReader();", with: """
startReader();

        if (!preset) preset = "medium";
        if (!tune) tune = "none";
        x265_log(param, X265_LOG_INFO, "Using preset %s & tune %s\\n", preset, tune);

""")
    }


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
          "-DMAIN12=ON",
          "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
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
          "-DENABLE_CLI=OFF",
          "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
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
        cmakeOnFlag(true, "ENABLE_CLI"),
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
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
