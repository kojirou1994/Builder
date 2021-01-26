import BuildSystem

struct BuildAll: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [

      PackageBuildAllCommand<Ninja>.self,
      PackageBuildAllCommand<CAres>.self,
      PackageBuildAllCommand<FdkAac>.self,
      PackageBuildAllCommand<Ffmpeg>.self,
      PackageBuildAllCommand<Ffms>.self,
      PackageBuildAllCommand<Lsmash>.self,
      PackageBuildAllCommand<Opus>.self,
      PackageBuildAllCommand<x264>.self,
      PackageBuildAllCommand<x265>.self,
      PackageBuildAllCommand<Ogg>.self,
      PackageBuildAllCommand<Vorbis>.self,
      PackageBuildAllCommand<Mozjpeg>.self,
      PackageBuildAllCommand<Webp>.self,
      PackageBuildAllCommand<Png>.self,
      PackageBuildAllCommand<Aribb24>.self,
      PackageBuildAllCommand<Vpx>.self,
      PackageBuildAllCommand<Lame>.self,
      PackageBuildAllCommand<Opencore>.self,
      PackageBuildAllCommand<Ass>.self,
      PackageBuildAllCommand<Freetype>.self,
      PackageBuildAllCommand<Fribidi>.self,
      PackageBuildAllCommand<Harfbuzz>.self,
      PackageBuildAllCommand<Icu4c>.self,
      PackageBuildAllCommand<Flac>.self,
      PackageBuildAllCommand<Ebml>.self,
      PackageBuildAllCommand<Matroska>.self,
      PackageBuildAllCommand<Fmt>.self,
      PackageBuildAllCommand<Pcre2>.self,
      PackageBuildAllCommand<Pugixml>.self,
      PackageBuildAllCommand<Mkvtoolnix>.self,
      PackageBuildAllCommand<Jpcre2>.self,
      PackageBuildAllCommand<Xml2>.self,
      PackageBuildAllCommand<Xz>.self,
      PackageBuildAllCommand<Xslt>.self,
      PackageBuildAllCommand<Gcrypt>.self,
      PackageBuildAllCommand<OpusFile>.self,
      PackageBuildAllCommand<Opusenc>.self,
      PackageBuildAllCommand<OpusTools>.self,
      PackageBuildAllCommand<Mediainfo>.self,
      PackageBuildAllCommand<Zstd>.self,
    ])
  }
}
