public enum PackageProduct {
  case bin(String)
  /// name is the filename without extension
  case library(name: String, headers: [String], exported: [String])
  case header(String)
}

extension PackageProduct {

  public static func library(name: String, headers: [String]) -> Self {
    .library(name: name, headers: headers, exported: [])
  }

}
