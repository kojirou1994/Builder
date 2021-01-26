import ArgumentParser
import Foundation
import URLFileManager
import BuildSystem

struct BuildCli: ParsableCommand {

  static var configuration: CommandConfiguration {
    .init(subcommands: [
      Build.self,
      BuildAll.self
    ])
  }

  struct Build: ParsableCommand {
    static var configuration: CommandConfiguration {
      .init(subcommands: [
        PackageBuildCommand<Ninja>.self,
        PackageBuildCommand<CAres>.self,
        PackageBuildCommand<FdkAac>.self,
        PackageBuildCommand<Ffmpeg>.self,
        PackageBuildCommand<Ffms>.self,
        PackageBuildCommand<Lsmash>.self,
        PackageBuildCommand<Opus>.self,
        PackageBuildCommand<x264>.self,
        PackageBuildCommand<x265>.self,
        PackageBuildCommand<Ogg>.self,
        PackageBuildCommand<Vorbis>.self,
        PackageBuildCommand<Mozjpeg>.self,
        PackageBuildCommand<Webp>.self,
        PackageBuildCommand<Png>.self,
        PackageBuildCommand<Aribb24>.self,
        PackageBuildCommand<Vpx>.self,
        PackageBuildCommand<Lame>.self,
        PackageBuildCommand<Opencore>.self,
        PackageBuildCommand<Ass>.self,
        PackageBuildCommand<Freetype>.self,
        PackageBuildCommand<Fribidi>.self,
        PackageBuildCommand<Harfbuzz>.self,
        PackageBuildCommand<Icu4c>.self,
        PackageBuildCommand<Flac>.self,
        PackageBuildCommand<Ebml>.self,
        PackageBuildCommand<Matroska>.self,
        PackageBuildCommand<Fmt>.self,
        PackageBuildCommand<Pcre2>.self,
        PackageBuildCommand<Pugixml>.self,
        PackageBuildCommand<Mkvtoolnix>.self,
        PackageBuildCommand<Jpcre2>.self,
        PackageBuildCommand<Xml2>.self,
        PackageBuildCommand<Xz>.self,
        PackageBuildCommand<Xslt>.self,
        PackageBuildCommand<Gcrypt>.self,
        PackageBuildCommand<OpusFile>.self,
        PackageBuildCommand<Opusenc>.self,
        PackageBuildCommand<OpusTools>.self,
        PackageBuildCommand<Mediainfo>.self,
        PackageBuildCommand<Zstd>.self,
      ])
    }
  }
}

BuildCli.main()
