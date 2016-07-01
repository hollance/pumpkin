import simd
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

  /*! The point in the sprite where it is attached to the node, normalized to
      the range 0.0f - 1.0f. The default value is (0.5f, 0.5f), i.e. the center
      of the image. */
  public var anchorPoint = float2(0.5, 0.5) {
    didSet { needsRedraw = true }
  }

  /*! Whether the sprite is displayed horizontally flipped. */
  public var flipX: Bool = false {
    didSet { needsRedraw = true }
  }

  /*! Whether the sprite is displayed vertically flipped. */
  public var flipY: Bool = false {
    didSet { needsRedraw = true }
  }

  public var contentSize: float2 {
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

  public var texCoords: float4 {
    if let sf = activeSpriteFrame {
      return sf.texCoords
    } else if let sf = spriteFrame {
      return sf.texCoords
    } else {
      return float4(0, 0, 1, 1)
    }
  }

  public var color = float4(1, 1, 1, 1) {
    didSet { needsRedraw = true }
  }

  public var alpha: Float = 1 {
    didSet { needsRedraw = true }
  }

  // TODO: these belong only in Node
  public var position = float2(0, 0)
  public var scale = float2(1, 1)
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
  public var placeholderContentSize = float2.zero {
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
  public var boundingBox: float4 {
    let quad = texturedQuad

    var minX =  Float.infinity
    var maxX = -Float.infinity
    var minY =  Float.infinity
    var maxY = -Float.infinity

    func check(v: TexturedVertex) {
      let x = v.position.x
      let y = v.position.y

      if x > maxX { maxX = x }
      if x < minX { minX = x }
      if y > maxY { maxY = y }
      if y < minY { minY = y }
    }

    check(quad.tl)
    check(quad.tr)
    check(quad.br)
    check(quad.bl)

    return float4(minX, minY, maxX, maxY)
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
        quad.tl.position = float2.zero
        quad.tr.position = float2.zero
        quad.br.position = float2.zero
        quad.bl.position = float2.zero
      } else {
        // The order of the transforms is as follows:
        //   1. adjust for anchor point
        //   2. scale
        //   3. rotate
        //   4. translate

        let ax1 = -anchorPoint.x * contentSize.x
        let ay1 = -anchorPoint.y * contentSize.y
        let ax2 = ax1 + contentSize.x
        let ay2 = ay1 + contentSize.y

        quad.tl.position = float2(ax1, ay1)
        quad.tr.position = float2(ax2, ay1)
        quad.br.position = float2(ax2, ay2)
        quad.bl.position = float2(ax1, ay2)

        let tx1 = flipX ? texCoords.z : texCoords.x
        let ty1 = flipY ? texCoords.w : texCoords.y
        let tx2 = flipX ? texCoords.x : texCoords.z
        let ty2 = flipY ? texCoords.y : texCoords.w

        quad.tl.texCoord = float2(tx1, ty1)
        quad.tr.texCoord = float2(tx2, ty1)
        quad.br.texCoord = float2(tx2, ty2)
        quad.bl.texCoord = float2(tx1, ty2)

        let transform = node?.transform ?? float4x4.identity

        let spriteColor: [GLubyte] = [
          GLubyte(color.x * 255),
          GLubyte(color.y * 255),
          GLubyte(color.z * 255),
          GLubyte(color.w * alpha * 255),
        ]

        let m = transform.openGLMatrix

        func process(inout v: TexturedVertex) {
          let x = v.position.x
          let y = v.position.y

          v.position.x = m[0] * x + m[4] * y + m[12]
          v.position.y = m[1] * x + m[5] * y + m[13]

          v.r = spriteColor[0]
          v.g = spriteColor[1]
          v.b = spriteColor[2]
          v.a = spriteColor[3]
        }

        process(&quad.tl)
        process(&quad.tr)
        process(&quad.br)
        process(&quad.bl)
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

    glUniformMatrix4fv(GLint(shaderProgram.uniforms.matrix), 1, GLboolean(GL_FALSE), context.matrix.openGLMatrix)

    glEnableVertexAttribArray(shaderProgram.attributes.position)
    glEnableVertexAttribArray(shaderProgram.attributes.color)
    glEnableVertexAttribArray(shaderProgram.attributes.texCoord)

    var quad = texturedQuad
    let stride = GLsizei(sizeof(TexturedVertex))
    let indices: [GLushort] = [ 0, 2, 1, 0, 3, 2 ]  // counter-clockwise!

    glVertexAttribPointer(shaderProgram.attributes.position, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, &quad)
    glVertexAttribPointer(shaderProgram.attributes.texCoord, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, &quad.tl.texCoord )
    glVertexAttribPointer(shaderProgram.attributes.color, 4, GLenum(GL_UNSIGNED_BYTE), GLboolean(GL_TRUE), stride, &quad.tl.r)

    if let texture = texture {
      glBlendFunc(texture.premultipliedAlpha ? GLenum(GL_ONE) : GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
      glBindTexture(GLenum(GL_TEXTURE_2D), texture.name)
    }

    glDrawElements(GLenum(GL_TRIANGLES), 6, GLenum(GL_UNSIGNED_SHORT), indices)

    glDisableVertexAttribArray(shaderProgram.attributes.texCoord)
    glDisableVertexAttribArray(shaderProgram.attributes.color)
    glDisableVertexAttribArray(shaderProgram.attributes.position)

    glBindTexture(GLenum(GL_TEXTURE_2D), 0)

    debug.drawCalls += 1
    debug.triangleCount += 2
    debug.dirtyCount += 1

    needsRedraw = false

    logOpenGLError()
  }
}
