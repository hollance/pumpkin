import simd

/*! Describes a region inside a sprite sheet or texture atlas. */
public struct SpriteFrame {

  /*! The untransformed size of the sprite in points. */
  public var contentSize = float2.zero

  /*! The normalized texture coordinates in the sprite sheet (range 0.0 - 1.0). */
  public var texCoords = float4.zero
}

extension SpriteFrame: CustomStringConvertible {
  public var description: String {
    return String(format: "contentSize: (%g x %g), texCoords: (%g, %g)", contentSize.x, contentSize.y, texCoords.x, texCoords.y, texCoords.z, texCoords.w)
  }
}
