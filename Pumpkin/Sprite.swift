import GLKit
import OpenGLES

/*! Visual for a node that draws part of a texture. */
public class Sprite: Visual, Tweenable, Renderer {
  public weak var node: Node?

  private var quadDirty = true

  public var needsRedraw: Bool = true {
    didSet {
      if needsRedraw {
        quadDirty = true
      }
    }
  }

  public var hidden: Bool = false {
    didSet { needsRedraw = true }
  }

  public var anchorPoint = GLKVector2Make(0.5, 0.5) {
    didSet { needsRedraw = true }
  }

  public var flipX: Bool = false {
    didSet { needsRedraw = true }
  }

  public var flipY: Bool = false {
    didSet { needsRedraw = true }
  }

  public var contentSize: GLKVector2 {
    if let sf = activeSpriteFrame {
      return sf.contentSize
    } else if let sf = spriteFrame {
      return sf.contentSize
    } else if let tex = texture {
      return tex.contentSize
    } else {
      return placeholderContentSize
    }
  }

  public var texCoords: GLKVector4 {
    if let sf = activeSpriteFrame {
      return sf.texCoords
    } else if let sf = spriteFrame {
      return sf.texCoords
    } else {
      return GLKVector4Make(0, 0, 1, 1)
    }
  }

  public var color = GLKVector4Make(1, 1, 1, 1) {
    didSet { needsRedraw = true }
  }

  public var alpha: Float = 1 {
    didSet { needsRedraw = true }
  }

  // TODO: these belong only in Node
  public var position = GLKVector2Make(0, 0)
  public var scale = GLKVector2Make(1, 1)
  public var angle: Float = 0


  /*! If this is not nil, the sprite is drawn using only a small region of a
      larger texture atlas. */
  public var spriteFrame: SpriteFrame? {
    didSet { needsRedraw = true }
  }

  /*! If this is not nil, then the sprite represents an entire texture. That is
      useful for large background images that do not fit into a sprite sheet. */
  public var texture: Texture? {
    didSet { needsRedraw = true }
  }

  /*! A placeholder is a sprite without a texture and only a color. If texture
      and spriteFrame are both nil, set this property to make it a placeholder. */
  public var placeholderContentSize = GLKVector2() {
    didSet { needsRedraw = true }
  }

  /*! Lower values draw first and therefore appear behind other sprites. */
  public var drawOrder = 0

  /*!
    Returns an axis-aligned bounding box (AABB) that takes into consideration
    the sprite's anchor point, and the owning node's scale and rotation. The
    returned box is in the parent node's coordinate system.

    A "box" is expressed as a GLKVector4, where x is the left edge, y is the
    top edge, z is the right edge, and w is the bottom edge. The width of the 
    bounding box is (z - x); the height is (w - y).

    Note: The value of boundingBox is incorrect when the sprite is hidden!
  */
  public var boundingBox: GLKVector4 {
    let quad = texturedQuad

    var minX =  Float.infinity
    var maxX = -Float.infinity
    var minY =  Float.infinity
    var maxY = -Float.infinity

//TODO: fix this
    for i in 0..<4 {
      var v: TexturedVertex
      switch i {
      case 0: v = quad.tl
      case 1: v = quad.tr
      case 2: v = quad.br
      case 3: v = quad.bl
      default: fatalError("fuck off")
      }

      let x = v.position.x
      let y = v.position.y

//      let vertex = quad.vertex[i]
//      let x = vertex.position.x
//      let y = vertex.position.y

      if x > maxX { maxX = x }
      if x < minX { minX = x }
      if y > maxY { maxY = y }
      if y < minY { minY = y }
    }

    return GLKVector4Make(minX, minY, maxX, maxY)
  }

  /*! A cached copy of the quad. We only recompute this if quadDirty. */
  private var quad = TexturedQuad()

  /*! Returns the quad that is used to draw this sprite using OpenGL. */
  public var texturedQuad: TexturedQuad {
    if quadDirty {
      quadDirty = false

      if self.hidden {
        // This is a quick optimization so not all quads have to be
        // re-ordered if you just want to hide one sprite.

        quad.tl.position = GLKVector2Make(0, 0)  //float2()
        quad.tr.position = GLKVector2Make(0, 0)  //float2()
        quad.br.position = GLKVector2Make(0, 0)  //float2()
        quad.bl.position = GLKVector2Make(0, 0)  //float2()

//        quad.vertex[0].position = GLKVector2Make(0, 0)  //float2()
//        quad.vertex[1].position = GLKVector2Make(0, 0)  //float2()
//        quad.vertex[2].position = GLKVector2Make(0, 0)  //float2()
//        quad.vertex[3].position = GLKVector2Make(0, 0)  //float2()
      }
      else
      {
        // The order of the transforms is as follows:
        //   1. adjust for anchor point
        //   2. scale
        //   3. rotate
        //   4. translate

        let ax1 = -anchorPoint.x * contentSize.x
        let ay1 = -anchorPoint.y * contentSize.y
        let ax2 = ax1 + contentSize.x
        let ay2 = ay1 + contentSize.y

        quad.tl.position = GLKVector2Make(ax1, ay1)
        quad.tr.position = GLKVector2Make(ax2, ay1)
        quad.br.position = GLKVector2Make(ax2, ay2)
        quad.bl.position = GLKVector2Make(ax1, ay2)

//        quad.vertex[0].position = GLKVector2Make(ax1, ay1)
//        quad.vertex[1].position = GLKVector2Make(ax2, ay1)
//        quad.vertex[2].position = GLKVector2Make(ax2, ay2)
//        quad.vertex[3].position = GLKVector2Make(ax1, ay2)

        let tx1 = flipX ? texCoords.z : texCoords.x
        let ty1 = flipY ? texCoords.w : texCoords.y
        let tx2 = flipX ? texCoords.x : texCoords.z
        let ty2 = flipY ? texCoords.y : texCoords.w

        quad.tl.texCoord = GLKVector2Make(tx1, ty1)
        quad.tr.texCoord = GLKVector2Make(tx2, ty1)
        quad.br.texCoord = GLKVector2Make(tx2, ty2)
        quad.bl.texCoord = GLKVector2Make(tx1, ty2)

//        quad.vertex[0].texCoord = GLKVector2Make(tx1, ty1)
//        quad.vertex[1].texCoord = GLKVector2Make(tx2, ty1)
//        quad.vertex[2].texCoord = GLKVector2Make(tx2, ty2)
//        quad.vertex[3].texCoord = GLKVector2Make(tx1, ty2)

        let transform = node?.transform ?? GLKMatrix4Identity

        let spriteColor: [GLubyte] = [
          GLubyte(color.x * 255),
          GLubyte(color.y * 255),
          GLubyte(color.z * 255),
          GLubyte(color.w * alpha * 255),
        ]

        // TODO: ugh
        var m = [Float](count: 16, repeatedValue: 0)
        m[0] = transform.m00
        m[1] = transform.m01
        m[4] = transform.m10
        m[5] = transform.m11
        m[12] = transform.m30
        m[13] = transform.m31


        for t in 0..<4 {
          //TODO: kinda lame
          var v: TexturedVertex
          switch t {
          case 0: v = quad.tl
          case 1: v = quad.tr
          case 2: v = quad.br
          case 3: v = quad.bl
          default: fatalError("fuck off")
          }

          let x = v.position.x
          let y = v.position.y

//          let x = quad.vertex[t].position.x
//          let y = quad.vertex[t].position.y

//          quad.vertex[t].position.x = transform[0, 0] * x + transform[1, 0] * y + transform[3, 0]
//          quad.vertex[t].position.y = transform[0, 1] * x + transform[1, 1] * y + transform[3, 1]

          v.position = GLKVector2Make(
            m[0] * x + m[4] * y + m[12],
            m[1] * x + m[5] * y + m[13])

          v.r = spriteColor[0]
          v.g = spriteColor[1]
          v.b = spriteColor[2]
          v.a = spriteColor[3]

//          v.color = (UInt32(spriteColor[0]) <<  0) |
//                    (UInt32(spriteColor[1]) <<  8) |
//                    (UInt32(spriteColor[2]) << 16) |
//                    (UInt32(spriteColor[3]) << 24)

          switch t {
          case 0: quad.tl = v
          case 1: quad.tr = v
          case 2: quad.br = v
          case 3: quad.bl = v
          default: fatalError("fuck off")
          }
        }
      }
    }

    return quad
  }

  public init() { }

  deinit {
    //print("deinit \(self)")
  }

  // MARK: - Animations

  /*! Adds an animation to this sprite object. You need to add the animation
      before you can play it. */
  public func add(animation: Animation, withName name: String) {
    assert(animations[name] == nil, "Already have this animation")
    animations[name] = animation
  }

  /*! Plays the animation and keeps looping until you stop it or play another. */
  public func playAnimation(name: String) {
    playAnimation(name, fromFrame: 0)
  }

  /*! Plays the animation, starting at the frame you specified. */
  public func playAnimation(name: String, fromFrame frameIndex: Int) {
    assert(animations[name] != nil, "Unknown animation")
    activeAnimation = animations[name]
    activeFrameIndex = frameIndex
    activeSpriteFrame = activeAnimation!.spriteFrames[activeFrameIndex]
    elapsed = 0
    currentLoop = 0
    needsRedraw = true
  }

  /*! Stops the current animation, if any. Useful for looping animations.
      This always restores the original sprite frame. */
  public func stopAnimation() {
    activeAnimation = nil
    activeSpriteFrame = nil
    needsRedraw = true
  }

  private(set) public var animations: [String : Animation] = [:]
  private var activeAnimation: Animation?
  private var activeSpriteFrame: SpriteFrame?
  private var activeFrameIndex = 0
  private var elapsed: Float = 0
  private var currentLoop = 0

  private func updateAnimations(dt: Float) {
    if let activeAnimation = activeAnimation {
      if elapsed >= activeAnimation.timePerFrame {
        needsRedraw = true
        elapsed = 0
        activeFrameIndex += 1

        // Reached the end of the animation?
        if activeFrameIndex == activeAnimation.spriteFrames.count {
          activeFrameIndex = 0
          currentLoop += 1
          if activeAnimation.loops > 0 && currentLoop == activeAnimation.loops {
            if activeAnimation.restoreOriginalFrame {
              activeSpriteFrame = nil
            }
            self.activeAnimation = nil
            return
          }
        }

        activeSpriteFrame = activeAnimation.spriteFrames[activeFrameIndex]
      } else {
        elapsed += dt
      }
    }
  }

  public func update(dt: Float) {
    updateAnimations(dt)
  }

  // MARK: - Rendering

  /* This draws the Sprite when it is not part of a SpriteBatch. */
  public func render(context: RenderContext) {
    let shaderProgram: ShaderProgram
    if texture != nil {
      shaderProgram = context.texturedShader
    } else {
      shaderProgram = context.coloredShader
    }

    glUseProgram(shaderProgram.programName)

    var m = [Float](count: 16, repeatedValue: 0)
    m[0] = context.matrix.m00
    m[1] = context.matrix.m01
    m[2] = context.matrix.m02
    m[3] = context.matrix.m03
    m[4] = context.matrix.m10
    m[5] = context.matrix.m11
    m[6] = context.matrix.m12
    m[7] = context.matrix.m13
    m[8] = context.matrix.m20
    m[9] = context.matrix.m21
    m[10] = context.matrix.m22
    m[11] = context.matrix.m23
    m[12] = context.matrix.m30
    m[13] = context.matrix.m31
    m[14] = context.matrix.m32
    m[15] = context.matrix.m33

    let uniforms = shaderProgram.uniforms
    glUniformMatrix4fv(GLint(uniforms.matrix), 1, GLboolean(GL_FALSE), m)

    glEnableVertexAttribArray(ShaderAttributes.position.rawValue)
    glEnableVertexAttribArray(ShaderAttributes.color.rawValue)
    glEnableVertexAttribArray(ShaderAttributes.texCoord.rawValue)

          // how do I get a pointer to just this variable?
          // unsafeAddressOf() doesn't seem to work
//    let pointer = UnsafePointer<Void>(&quad)

    let quads = [texturedQuad]

    quads.withUnsafeBufferPointer { buf in
      let pointer = UnsafePointer<UInt8>(buf.baseAddress)
      let stride = GLsizei(sizeof(TexturedVertex))
      let indices: [GLushort] = [ 0, 2, 1, 0, 3, 2 ]  // counter-clockwise!

      glVertexAttribPointer(ShaderAttributes.position.rawValue, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, pointer)
      glVertexAttribPointer(ShaderAttributes.texCoord.rawValue, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, pointer + 8)
      glVertexAttribPointer(ShaderAttributes.color.rawValue, 4, GLenum(GL_UNSIGNED_BYTE), GLboolean(GL_TRUE), stride, pointer + 16)

      if let texture = texture {
        glBlendFunc(texture.premultipliedAlpha ? GLenum(GL_ONE) : GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glBindTexture(GLenum(GL_TEXTURE_2D), texture.name)
      }

      glDrawElements(GLenum(GL_TRIANGLES), 6, GLenum(GL_UNSIGNED_SHORT), indices)
    }

    glDisableVertexAttribArray(ShaderAttributes.texCoord.rawValue)
    glDisableVertexAttribArray(ShaderAttributes.color.rawValue)
    glDisableVertexAttribArray(ShaderAttributes.position.rawValue)

    glBindTexture(GLenum(GL_TEXTURE_2D), 0)

    debug.drawCalls += 1
    debug.triangleCount += 2
    debug.dirtyCount += 1

    needsRedraw = false

    logOpenGLError()
  }
}
