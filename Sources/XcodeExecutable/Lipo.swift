import ExecutableDescription

/*
 one of -create, -thin <arch_type>, -extract <arch_type>, -remove <arch_type>, -replace <arch_type> <file_name>, -verify_arch <arch_type> ... , -archs, -info, or -detailed_info must be specified
 usage: lipo <input_file> <command> [<options> ...]
 command is one of:
 -archs
 -create
 -detailed_info
 -extract <arch_type> [-extract <arch_type> ...]
 -extract_family <arch_type> [-extract_family <arch_type> ...]
 -info
 -remove <arch_type> [-remove <arch_type> ...]
 -replace <arch_type> <file_name> [-replace <arch_type> <file_name> ...]
 -thin <arch_type>
 -verify_arch <arch_type> ...
 options are one or more of:
 -arch <arch_type> <input_file>
 -hideARM64
 -output <output_file>
 -segalign <arch_type> <alignment>
 */
public struct Lipo: Executable {
  public init(files: [String], output: String) {
    self.files = files
    self.output = output
  }

  public static let executableName = "lipo"

  public let files: [String]
  public let output: String

  public var arguments: [String] {
    files + ["-create", "-output", output]
  }
}
