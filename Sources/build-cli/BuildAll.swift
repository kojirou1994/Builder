import BuildSystem

struct BuildAll: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [
      PackageBuildAllCommand<Aribb24>.self,
      PackageBuildAllCommand<Ass>.self,
      PackageBuildAllCommand<BoringSSL>.self,
      PackageBuildAllCommand<CAres>.self,
      PackageBuildAllCommand<Ebml>.self,
      PackageBuildAllCommand<FdkAac>.self,
      PackageBuildAllCommand<Ffmpeg>.self,
      PackageBuildAllCommand<Ffms>.self,
      PackageBuildAllCommand<Flac>.self,
      PackageBuildAllCommand<Fmt>.self,
      PackageBuildAllCommand<Freetype>.self,
      PackageBuildAllCommand<Fribidi>.self,
      PackageBuildAllCommand<Gcrypt>.self,
      PackageBuildAllCommand<GnuTar>.self,
      PackageBuildAllCommand<GpgError>.self,
      PackageBuildAllCommand<Harfbuzz>.self,
      PackageBuildAllCommand<Icu4c>.self,
      PackageBuildAllCommand<Jpcre2>.self,
      PackageBuildAllCommand<JpegXL>.self,
      PackageBuildAllCommand<Lame>.self,
      PackageBuildAllCommand<Lsmash>.self,
      PackageBuildAllCommand<Matroska>.self,
      PackageBuildAllCommand<Mbedtls>.self,
      PackageBuildAllCommand<Mediainfo>.self,
      PackageBuildAllCommand<Mkvtoolnix>.self,
      PackageBuildAllCommand<Mozjpeg>.self,
      PackageBuildAllCommand<Ninja>.self,
      PackageBuildAllCommand<Ogg>.self,
      PackageBuildAllCommand<Opencore>.self,
      PackageBuildAllCommand<Openssl>.self,
      PackageBuildAllCommand<Opus>.self,
      PackageBuildAllCommand<OpusTools>.self,
      PackageBuildAllCommand<Opusenc>.self,
      PackageBuildAllCommand<Opusfile>.self,
      PackageBuildAllCommand<P7Zip>.self,
      PackageBuildAllCommand<Pcre2>.self,
      PackageBuildAllCommand<Png>.self,
      PackageBuildAllCommand<Pugixml>.self,
      PackageBuildAllCommand<Sdl2>.self,
      PackageBuildAllCommand<Vorbis>.self,
      PackageBuildAllCommand<Vpx>.self,
      PackageBuildAllCommand<Webp>.self,
      PackageBuildAllCommand<Xml2>.self,
      PackageBuildAllCommand<Xslt>.self,
      PackageBuildAllCommand<Xz>.self,
      PackageBuildAllCommand<Zstd>.self,
      PackageBuildAllCommand<Zvbi>.self,
      PackageBuildAllCommand<x264>.self,
      PackageBuildAllCommand<x265>.self,
    ])
  } // end of configuration
} // end of BuildAll