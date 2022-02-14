import URLFileManager
import KwiftUtility
import XcodeExecutable
import ExecutableLauncher

public struct PackageBuildAllCommand<T: Package>: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(commandName: T.name,
          abstract: "",
          discussion: "")
  }

  public init() {}

  @OptionGroup
  var builderOptions: BuilderOptions

  @OptionGroup
  var package: T

  @Option
  var arch: [TargetArch] = TargetArch.allCases

  @Option
  var system: [TargetSystem] = TargetSystem.allCases

  @Option(help: "Pack xcframework using specific library(.a) filename.")
  var packXc: String?

  @Flag(help: "Auto pack xcframework, if package supports.")
  var autoPackXC: Bool = false

  @Flag(help: "Keep temp files when packing xcframeworks.")
  var keepTemp: Bool = false

  @Flag(name: [.short], inversion: .prefixedEnableDisable, help: "If enabled, program will create framework to pack xcframework.")
  var autoModulemap: Bool = true

  public mutating func run() throws {
    var builtPackages = [TargetSystem : [(arch: TargetArch, result: PackageBuildResult)]]()
    var failedTargets = [TargetTriple]()
    let unsupportedTargets = [TargetTriple]()

    for target in TargetTriple.allValid where Set(arch).contains(target.arch) && Set(system).contains(target.system) {
      do {
        print("Building \(target)")
        let builder = try Builder(options: builderOptions, target: target, addLibInfoInPrefix: true)

        let result = try builder.startBuild(package: package, version: builderOptions.packageVersion, libraryType: builderOptions.library)

        builtPackages[target.system, default: []].append((target.arch, result))
      } catch {
        print("ERROR!", error)
        failedTargets.append(target)
      }
    }
    print("\n\n\n")
    print("FAILED TARGETS:", failedTargets)
    print("UNSUPPORTED TARGETS:", unsupportedTargets)

    if builtPackages.isEmpty {
      print("NO BUILT PACKAGES!")
      return
    }

    let fm = URLFileManager.default

    func packXCFramework(frameworkName: String, libraryName: String, headerRoot: String, headers: [String]?, shimedHeaders: [String], isStatic: Bool) throws {
      print("Packing xcframework from \(libraryName)...")

      let ext = isStatic ? "a" : "dylib"
      let libraryFilename = "lib" + libraryName + "." + ext
      let output = "\(frameworkName)_\(isStatic ? "static" : "dynamic").xcframework"

      if case let outputURL = URL(fileURLWithPath: output),
         fm.fileExistance(at: outputURL).exists {
        print("Remove existed xcframework.")
        try retry(body: fm.removeItem(at: outputURL))
      }
      let xcTempDirectory = URL(fileURLWithPath: "PACK_XC-\(UUID().uuidString)")
      try retry(body: fm.createDirectory(at: xcTempDirectory))
      defer {
//        try? retry(body: fm.removeItem(at: lipoWorkingDirectory))
      }

      var createXCFramework = XcodeCreateXCFramework(output: output)

      try builtPackages.forEach { (system, systemBuiltPackages) in

        precondition(!systemBuiltPackages.isEmpty)
        let libraryFileURL: URL
        let tmpDirectory = xcTempDirectory.appendingPathComponent("\(system)-\(systemBuiltPackages.map(\.arch.rawValue).joined(separator: "_"))")
        if systemBuiltPackages.count == 1 {
          libraryFileURL = systemBuiltPackages[0].result.prefix.lib.appendingPathComponent(libraryFilename)
            .resolvingSymlinksInPath()
        } else {
          try retry(body: fm.createDirectory(at: tmpDirectory))
          let fatOutput = tmpDirectory.appendingPathComponent(frameworkName)
          let lipoArguments = ["-create", "-output", fatOutput.path]
            + systemBuiltPackages.map { $0.result.prefix.lib.appendingPathComponent(libraryFilename).path }
          let lipo = AnyExecutable(executableName: "lipo",
                                   arguments: lipoArguments)
          try lipo.launch(use: TSCExecutableLauncher(outputRedirection: .none))
          libraryFileURL = fatOutput
        }

        let headerIncludeDir = tmpDirectory.appendingPathComponent("include")
        try fm.createDirectory(at: headerIncludeDir)

        // copy specified headers
        try headers?.forEach { headerPath in

          let headerDstURL = headerIncludeDir.appendingPathComponent(headerPath)
          let headerSuperDirectory = headerDstURL.deletingLastPathComponent()
          try fm.createDirectory(at: headerSuperDirectory)
          try fm.copyItem(at: systemBuiltPackages[0].result.prefix.include.appendingPathComponent(headerRoot).appendingPathComponent(headerPath), to: headerDstURL)

        }

        // create tmp framework
        let frameworkFilename = frameworkName + ".framework"
        let tmpFrameworkDirectory = tmpDirectory.appendingPathComponent(frameworkFilename)
        try fm.createDirectory(at: tmpFrameworkDirectory)
        let frameworkHeadersDirectory = tmpFrameworkDirectory.appendingPathComponent("Headers")

        if let copiedHeaders = headers {
          if copiedHeaders.isEmpty {
            // copy all headers
            try fm.copyItem(at: systemBuiltPackages[0].result.prefix.include.appendingPathComponent(headerRoot), to: frameworkHeadersDirectory)
          } else {
            try fm.copyItem(at: headerIncludeDir, to: frameworkHeadersDirectory)
          }

          if autoModulemap {
            let frameworkModulesDirectory = tmpFrameworkDirectory.appendingPathComponent("Modules")

            try fm.createDirectory(at: frameworkModulesDirectory)

            var headerFiles = [String]()
            _ = fm.forEachContent(in: frameworkHeadersDirectory) { file in
              if file.pathExtension == "h" {
                var relativePath = file.path.dropFirst(frameworkHeadersDirectory.path.count)
                if relativePath.hasPrefix("/") {
                  relativePath.removeFirst()
                }
                headerFiles.append(String(relativePath))
              }
            }
            let shimFilename = "\(frameworkName)_shim.h"
            let shimURL = frameworkHeadersDirectory.appendingPathComponent(shimFilename)
            let shimContent = (shimedHeaders.isEmpty ? headerFiles : shimedHeaders).map { "#include \"\($0)\"" }.joined(separator: "\n")
            try shimContent
              .write(to: shimURL, atomically: true, encoding: .utf8)

            let modulemap = """
            framework module \(frameworkName) {
            \(headerFiles.map { "//  header \"\($0)\"" }.joined(separator: "\n"))
              umbrella header "\(shimFilename)"
              export *
              module * { export * }
              //requires objc
            }
            """
            try modulemap.write(to: frameworkModulesDirectory.appendingPathComponent("module.modulemap"), atomically: true, encoding: .utf8)

          }
        } else {
          // no header
        }

        try fm.copyItem(at: libraryFileURL, to: tmpFrameworkDirectory.appendingPathComponent(frameworkName))

        createXCFramework.components.append(.framework(tmpFrameworkDirectory.path))

      }

      /*
       https://developer.apple.com/forums/thread/666335
       It seems like using lipo for these combinations might be necessary:
       ios-arm64-simulator and ios-x86_64-simulator
       ios-arm64-maccatalyst and ios-x86_64-maccatalyst
       macos-x86_64 and macos-arm64
       */

      print()
      print()
      try createXCFramework
        .launch(use: TSCExecutableLauncher(outputRedirection: .none))
    }

    let products = builtPackages.values.first!.first!.result.products

    try products.forEach { product in
      switch product {
      case let .library(name: frameworkName, libname: libraryName, headerRoot: headerRoot, headers: headers, shimedHeaders: shimedHeaders):
        if autoPackXC || libraryName == packXc || frameworkName == packXc {
          func pack(isStatic: Bool) throws {
            try packXCFramework(frameworkName: frameworkName, libraryName: libraryName, headerRoot: headerRoot, headers: headers, shimedHeaders: shimedHeaders, isStatic: isStatic)
          }
          try pack(isStatic: builderOptions.library.buildStatic)
          if builderOptions.library == .all {
            try pack(isStatic: false)
          }
        }
      default:
        break
      }
    }

  }
}
