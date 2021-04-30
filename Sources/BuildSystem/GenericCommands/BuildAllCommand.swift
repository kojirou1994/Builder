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

    for target in TargetTriple.allValid {
      do {
        print("Building \(target)")
        let builder = try Builder(options: builderOptions, target: target, addLibInfoInPrefix: true, deployTarget: nil)

        let result = try builder.startBuild(package: package, version: builderOptions.packageVersion)

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

    func packXCFramework(libraryName: String, headers: [String]?, isStatic: Bool) throws {
      print("Packing xcframework from \(libraryName)...")

      let ext = isStatic ? "a" : "dylib"
      let libraryFilename = libraryName + "." + ext
      let output = "\(libraryName)_\(isStatic ? "static" : "dynamic").xcframework"

      if case let outputURL = URL(fileURLWithPath: output),
         fm.fileExistance(at: outputURL).exists {
        print("Remove old xcframework.")
        try retry(body: fm.removeItem(at: outputURL))
      }
      let xcTempDirectory = URL(fileURLWithPath: "PACK_XC-\(UUID().uuidString)")
      try retry(body: fm.createDirectory(at: xcTempDirectory))
      defer {
        //        try? retry(body: fm.removeItem(at: lipoWorkingDirectory))
      }

      var createXCFramework = XcodeCreateXCFramework(output: output)

      try builtPackages.forEach { (system, systemPackages) in

        precondition(!systemPackages.isEmpty)
        let libraryFileURL: URL
        let tmpDirectory = xcTempDirectory.appendingPathComponent("\(system)-\(systemPackages.map(\.arch.rawValue).joined(separator: "_"))")
        if systemPackages.count == 1 {
          libraryFileURL = systemPackages[0].result.prefix.lib.appendingPathComponent(libraryFilename)
            .resolvingSymlinksInPath()
        } else {
          try retry(body: fm.createDirectory(at: tmpDirectory))
          let fatOutput = tmpDirectory.appendingPathComponent(libraryFilename)
          let lipoArguments = ["-create", "-output", fatOutput.path]
            + systemPackages.map { $0.result.prefix.lib.appendingPathComponent(libraryFilename).path }
          let lipo = AnyExecutable(executableName: "lipo",
                                   arguments: lipoArguments)
          try lipo.launch(use: TSCExecutableLauncher(outputRedirection: .none))
          libraryFileURL = fatOutput
        }

        let headerIncludeDir: URL
        if let specificHeaders = headers {
          headerIncludeDir = tmpDirectory.appendingPathComponent("include")
          try fm.createDirectory(at: headerIncludeDir)
          try specificHeaders.forEach { headerFilename in
            let headerDstURL = headerIncludeDir.appendingPathComponent(headerFilename)
            let headerSuperDirectory = headerDstURL.deletingLastPathComponent()
            try fm.createDirectory(at: headerSuperDirectory)
            try fm.copyItem(at: systemPackages[0].result.prefix.include.appendingPathComponent(headerFilename),
                            to: headerDstURL)
          }
        } else {
          headerIncludeDir = systemPackages[0].result.prefix.include
        }
        if autoModulemap {
          // create tmp framework
          let frameworkName = libraryName + ".framework"
          let tmpFrameworkDirectory = tmpDirectory.appendingPathComponent(frameworkName)
          try fm.createDirectory(at: tmpFrameworkDirectory)
          let frameworkHeadersDirectory = tmpFrameworkDirectory.appendingPathComponent("Headers")

          try fm.copyItem(at: headerIncludeDir, to: frameworkHeadersDirectory)

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

          let shimFilename = "\(libraryName)_shim.h"
          let shimURL = frameworkHeadersDirectory.appendingPathComponent(shimFilename)
          let shimContent = headerFiles.map { "#include \"\($0)\"" }.joined(separator: "\n")
          try shimContent
            .write(to: shimURL, atomically: true, encoding: .utf8)

          let modulemap = """
          framework module \(libraryName) {
          \(headerFiles.map { "//  header \"\($0)\"" }.joined(separator: "\n"))
            umbrella header "\(shimFilename)"
            export *
            module * { export * }
            //requires objc
          }
          """
          try modulemap.write(to: frameworkModulesDirectory.appendingPathComponent("module.modulemap"), atomically: true, encoding: .utf8)

          try fm.copyItem(at: libraryFileURL, to: tmpFrameworkDirectory.appendingPathComponent(libraryName))

          createXCFramework.components.append(.framework(tmpFrameworkDirectory.path))
        } else {
          createXCFramework.components.append(.library(libraryFileURL.path, header: headerIncludeDir.path))
        }
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

    func packXCFramework(libraryName: String, headers: [String]?) throws {
      try packXCFramework(libraryName: libraryName, headers: headers, isStatic: builderOptions.library.buildStatic)
      if builderOptions.library == .all {
        try packXCFramework(libraryName: libraryName, headers: headers, isStatic: false)
      }
    }

    if let libraryName = packXc {
      try packXCFramework(libraryName: libraryName, headers: nil)
    }

    if autoPackXC {
      let products = builtPackages.values.first!.first!.result.products

      try products.forEach { product in
        switch product {
        case let .library(name: libraryName, headers: headers):
          try packXCFramework(libraryName: libraryName, headers: headers)
        default:
          break
        }
      }
    }
  }
}
