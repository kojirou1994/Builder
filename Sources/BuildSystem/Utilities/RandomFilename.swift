private let safeFilenameChars: StaticString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

func genRandomFilename(prefix: String, length: Int) -> String {
  var random = SystemRandomNumberGenerator()
  return prefix + safeFilenameChars.withUTF8Buffer { buffer -> String in
    assert(!buffer.isEmpty)
    if #available(OSX 11.0, *) {
      return String(unsafeUninitializedCapacity: length) { strBuffer -> Int in
        for index in strBuffer.indices {
          strBuffer[index] = buffer.randomElement(using: &random).unsafelyUnwrapped
        }
        return length
      }
    } else {
      var string = ""
      string.reserveCapacity(length)
      for _ in 0..<length {
        let char = Character(Unicode.Scalar(buffer.randomElement(using: &random).unsafelyUnwrapped))
        string.append(char)
      }
      return string
    }
  }
}
