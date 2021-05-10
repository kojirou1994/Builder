import BuildSystem

public struct Sdl2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.0.14"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    switch order.target.system {
    case .watchOS, .watchSimulator,
         .macCatalyst:
      throw PackageRecipeError.unsupportedTarget
    default: break
    }

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/libsdl-org/SDL.git")
    case .stable(let version):
      source = .tarball(url: "https://libsdl.org/release/SDL2-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try replace(contentIn: "CMakeLists.txt", matching: "DARWIN OR MACOSX", with: "DARWIN AND MACOSX")
    let systemName: String
    switch env.order.target.system {
    case .iphoneOS, .iphoneSimulator:
      systemName = "IOS"
    case .tvOS, .tvSimulator:
      systemName = "TVOS"
    case .macOS:
      systemName = "MACOSX"
    case .watchOS, .watchSimulator,
         .linuxGNU, .macCatalyst:
      systemName = "__ANY_SYSTEM"
    }
    try replace(contentIn: "CMakeLists.txt", matching: "# TODO: iOS?", with: "set(\(systemName) TRUE)")
    try replace(contentIn: "CMakeLists.txt", matching: "message_error(\"SDL_FILE must be enabled to build on MacOS X\")", with: "")
    if env.order.target.system != .macOS {
      let replaceContent: String
      switch env.order.target.system {
      case .macOS:
        replaceContent = ""
      case .iphoneOS, .iphoneSimulator:
        replaceContent = "file(GLOB MISC_SOURCES ${SDL2_SOURCE_DIR}/src/misc/ios/*.m)"
      default:
        replaceContent = ""
      }

      try replace(contentIn: "CMakeLists.txt", matching: "file(GLOB MISC_SOURCES ${SDL2_SOURCE_DIR}/src/misc/macosx/*.m)", with: replaceContent)
    }

    try env.inRandomDirectory { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(env.libraryType.buildShared, "SDL_SHARED"),
        cmakeOnFlag(env.libraryType.buildStatic, "SDL_STATIC"),
        cmakeOnFlag(env.libraryType.buildStatic, "SDL_STATIC_PIC"),
        // SDL_TEST
        cmakeOnFlag(env.order.target.system == .macOS, "VIDEO_OPENGLES"),
        cmakeOnFlag(env.order.target.system == .macOS, "VIDEO_OPENGL"),
        cmakeOnFlag(env.order.target.system == .macOS, "VIDEO_COCOA"),
        cmakeOnFlag(env.order.target.system == .macOS, "SDL_FILESYSTEM"),
        cmakeOnFlag(env.order.target.system == .macOS, "SDL_FILE"),
        cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        nil
      )

      try env.make(toolType: .ninja)
      if env.canRunTests {
        //          try env.make(toolType: .ninja, "test")
      }
      try env.make(toolType: .ninja, "install")
    }
  }

}
