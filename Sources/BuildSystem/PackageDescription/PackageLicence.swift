public enum PackageLicence {
  case autoSearch
  case sourceTree(files: [String])
  case std(StdLicence)
}

public enum StdLicence {
  case gpl
  case lgpl
  case bsd
  case apache
}
