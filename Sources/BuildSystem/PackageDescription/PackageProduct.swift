public enum PackageProduct {
  case bin(String)
  /// name is the filename without extension
  case library(name: String, headers: [String])
  case header(String)
}