public enum PackageProduct {
  case bin(String)

  /// name is xcode framework name, libname is library name without lib prefix and extension
  /// nil headers means no header is used, empty headers will copy all .h files
  case library(name: String, libname: String, headerRoot: String, headers: [String]?, shimedHeaders: [String])
  case header(String)
}

extension PackageProduct {

  public static func library(name: String, headers: [String]) -> Self {
    .library(name: name, libname: name, headerRoot: "", headers: headers, shimedHeaders: [])
  }

}
