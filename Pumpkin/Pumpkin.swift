//import simd
import GLKit
import OpenGLES

/*
 * Compile-time configuration options.
 */

//#ifdef DEBUG
//#define PP_DEBUG
//#endif

//let PP_DEBUG_LAYER_ENABLED = true
//
//let PP_USE_VBO = false           // both vertices and indices in VBO
//let PP_USE_VBO_INDICES = false   // indices in VBO, vertices not
//let PP_USE_VAO = false           // use only in combination with PP_USE_VBO
//
//let PP_BATCH_MAX_SPRITES = 500

/* A textured and colored vertex. Used for drawing sprites. */
public struct TexturedVertex {
  public var position = GLKVector2() //float2()
  public var texCoord = GLKVector2() //float2()
  //public var color = [GLubyte](count: 4, repeatedValue: 0)
  public var r: GLubyte = 0
  public var g: GLubyte = 0
  public var b: GLubyte = 0
  public var a: GLubyte = 0
//  public var color: UInt32 = 0

  // NOTE: weird shit happens without these extra bytes to pad the vertex
  // struct out to 32 bytes. Does Swift do this kind of padding already inside
  // the array in TexturedQuad, but without telling me about it?
  // (Note: might as well make color a GLKVector4 then)
  public var pad1: UInt32 = 0  // 24
  public var pad2: UInt32 = 0  // 28
  public var pad3: UInt32 = 0  // 32
}

extension TexturedVertex: CustomStringConvertible {
  public var description: String {
    return String(format: "pos %@, tex %@, color %d %d %d %d", NSStringFromGLKVector2(position), NSStringFromGLKVector2(texCoord), r, g, b, a)
  }
}

/* Used for drawing sprites. */
public struct TexturedQuad {
  // 0 = tl, 1 = tr, 2 = br (!), 3 = bl
  //public var vertex = ContiguousArray<TexturedVertex>(count: 4, repeatedValue: TexturedVertex())
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

/* A colored vertex. */
public struct ColoredVertex {
  public var position = GLKVector2() //float2()
  //public var color = [GLubyte](count: 4, repeatedValue: 0)
  public var r: GLubyte = 0
  public var g: GLubyte = 0
  public var b: GLubyte = 0
  public var a: GLubyte = 0

  // Extra padding to make it 16 bytes.
  public var pad1: UInt32 = 0  // 16

  public init() { }
}
