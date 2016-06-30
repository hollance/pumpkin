import simd

/*! A textured and colored vertex. Used for drawing sprites. */
public struct TexturedVertex {
  public var position = float2.zero
  public var texCoord = float2.zero

  public var r: GLubyte = 0
  public var g: GLubyte = 0
  public var b: GLubyte = 0
  public var a: GLubyte = 0

  /* Note: Swift apparently pads the struct to 32 bytes, so I've added those
     padding bytes here myself in order to make this clear. Alternatively, I
     could make color a vector of 4 floats instead of 4 bytes. */
  public var pad1: UInt32 = 0  // 24
  public var pad2: UInt32 = 0  // 28
  public var pad3: UInt32 = 0  // 32
}

extension TexturedVertex: CustomStringConvertible {
  public var description: String {
    return String(format: "pos (%g, %g), tex (%g, %g), color (%d, %d, %d, %d)", position.x, position.y, texCoord.x, texCoord.y, r, g, b, a)
  }
}

/*! Used for drawing sprites. */
public struct TexturedQuad {
  public var tl = TexturedVertex()
  public var tr = TexturedVertex()
  public var br = TexturedVertex()
  public var bl = TexturedVertex()
}

extension TexturedQuad: CustomStringConvertible {
  public var description: String {
    var s = ""
    s += "tl: \(tl)\n"
    s += "tr: \(tr)\n"
    s += "br: \(br)\n"
    s += "bl: \(bl)\n"
    return s
  }
}

/*! A colored vertex. */
public struct ColoredVertex {
  public var position = float2.zero

  public var r: GLubyte = 0
  public var g: GLubyte = 0
  public var b: GLubyte = 0
  public var a: GLubyte = 0

  /* Extra padding to make the struct an even 16 bytes. */
  public var pad: UInt32 = 0  // 16

  public init() { }
}
