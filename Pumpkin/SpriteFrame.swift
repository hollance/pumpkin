import GLKit

/*! Describes a region inside a sprite sheet or texture atlas. */
public struct SpriteFrame {

  /*! The untransformed size of the sprite in points. */
  public var contentSize = GLKVector2Make(0, 0)

  /*! The normalized texture coordinates in the sprite sheet (range 0.0 - 1.0). */
  public var texCoords = GLKVector4Make(0, 0, 0, 0)
}

extension SpriteFrame: CustomStringConvertible {
  public var description: String {
    return "contentSize: \(NSStringFromGLKVector2(contentSize)), texCoords: \(NSStringFromGLKVector4(texCoords))"
  }
}
