import Foundation

/*! Find an object by identity in an array. */
extension CollectionType where Generator.Element: AnyObject {
  public func find(object: Generator.Element) -> Int? {
    for (index, element) in self.enumerate() {
      if element === object {
        return index
      }
    }
    return nil
  }
}

extension Array where Element: AnyObject {
  public mutating func removeObject(object: Element) {
    if let index = find(object) {
      removeAtIndex(index)
    }
  }
}

/*
 * Returns a pseudo-random integer between 0 and n-1.
 *
 * This function is guaranteed to generate a uniform distribution of random
 * numbers.
 *
 * You don't need to seed this random generator. This function is thread-safe.
 */
public func PPRandomInt(n: Int) -> Int {
	return Int(arc4random_uniform(UInt32(n)))
}

/*
 * Returns a pseudo-random integer between min and max (inclusive).
 *
 * You don't need to seed this random generator. This function is thread-safe.
 */
public func PPRandomIntBetween(min: Int, _ max: Int) -> Int {
	return Int(arc4random_uniform(UInt32(max - min + 1))) + min
}

/*
 * Returns a pseudo-random float between 0 and 1.0 (inclusive) with a uniform
 * distribution.
 *
 * You don't need to seed this random generator. This function is thread-safe.
 */
public func PPRandomFloat() -> Float {
	return Float(arc4random())/0xFFFFFFFF
}

/*
 * Returns a pseudo-random float between low and max (inclusive) with a
 * uniform distribution.
 *
 * You don't need to seed this random generator. This function is thread-safe.
 */
public func PPRandomFloatBetween(min: Float, _ max: Float) -> Float {
	return ((Float(arc4random())/0xFFFFFFFF) * (max - min)) + min
}

/*
 * Randomly returns either 1 or -1.
 */
public func PPRandomSign() -> Int {
	return arc4random_uniform(2) == 1 ? 1 : -1
}
