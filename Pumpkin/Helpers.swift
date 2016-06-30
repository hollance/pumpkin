import Foundation

/*! Finds an object by identity in an array. */
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

/*! Removes a reference object from an array. */
extension Array where Element: AnyObject {
  public mutating func removeObject(object: Element) {
    if let index = find(object) {
      removeAtIndex(index)
    }
  }
}
