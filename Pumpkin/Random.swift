import Foundation

extension Int {
  /*! Returns a random integer in the specified range. */
  public static func random(range: Range<Int>) -> Int {
    return Int(arc4random_uniform(UInt32(range.endIndex - range.startIndex))) + range.startIndex
  }

  /*! Returns a random integer between 0 and n-1. */
  public static func random(n: Int) -> Int {
    return Int(arc4random_uniform(UInt32(n)))
  }

  /*! Returns a random integer in the range min...max, inclusive. */
  public static func random(min min: Int, max: Int) -> Int {
    assert(min < max)
    return Int(arc4random_uniform(UInt32(max - min + 1))) + min
  }
}

extension Float {
  /*! Returns a random floating point number between 0.0 and 1.0, inclusive. */
  public static func random() -> Float {
    return Float(arc4random()) / 0xFFFFFFFF
  }

  /*! Returns a random floating point number in the range min...max, inclusive. */
  public static func random(min min: Float, max: Float) -> Float {
    assert(min < max)
    return Float.random() * (max - min) + min
  }

  /*! Randomly returns either 1.0 or -1.0. */
  public static func randomSign() -> Float {
    return (arc4random_uniform(2) == 0) ? 1 : -1
  }
}
