import ArgumentParser
import Foundation
import URLFileManager

struct BuildCli: ParsableCommand {

  static var configuration: CommandConfiguration {
    .init(subcommands: [
      PackageCommand<FdkAac>.self,
      PackageCommand<Ffmpeg>.self,
      PackageCommand<Ffms>.self,
      PackageCommand<Lsmash>.self,
      PackageCommand<Opus>.self,
      PackageCommand<x264>.self,
      PackageCommand<x265>.self,
      PackageCommand<Ogg>.self,
      PackageCommand<Vorbis>.self,
      PackageCommand<Mozjpeg>.self,
      PackageCommand<Webp>.self,
      PackageCommand<Png>.self,
      PackageCommand<Aribb24>.self
    ])
  }

}

func buildLsmash(package: Lsmash, installBin: Bool) throws {

//
//  if installBin {
//    let products = """
//        boxdumper
//        muxer
//        remuxer
//        timelineeditor
//        """
//      .components(separatedBy: .newlines)
//    products.forEach { binName in
//      do {
//        print("Moving \(binName)")
//        let dstURL = URL(fileURLWithPath: "lsmash-\(binName)")
//        if fm.fileExistance(at: dstURL).exists {
//          try fm.removeItem(at: dstURL)
//        }
//        try fm.copyItem(at:
//                          usrDirectoryURL
//                          .appendingPathComponent("bin")
//                          .appendingPathComponent(binName),
//                        to: dstURL)
//      } catch {
//        print("ERROR", error)
//      }
//    }
//  }
}

#if DEBUG
struct TestCLI: ParsableCommand {
  init() {

  }

  @Option()
  var configure: [String] = []

  init(configure: [String]) {
    self.configure = configure
  }
}

let c = TestCLI(configure: [])
print(c.configure)
print(try TestCLI.parse([]).configure)
#else
#endif
BuildCli.main()
