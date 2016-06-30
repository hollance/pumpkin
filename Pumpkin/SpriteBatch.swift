import OpenGLES

/*!
  Draws a set of sprites that all share the same texture in a single draw call.
*/
public class SpriteBatch: Renderer {

  /*
    The Objective-C version had options for:
    
     - using VBOs for vertices and indices
     - using VBOs for indices but not vertices
     - using VAO in combination with VBO

    However, I've not implemented these options in the Swift version, since I
    want to port to Metal anyway.
  */

  /*! Note: To draw placeholder sprites, set texture to nil. This changes the
      shader program to the colored shader. */
  public var texture: Texture?

  private(set) public var sprites: [Sprite] = []

  private var maxSprites: Int
  private var quads: ContiguousArray<TexturedQuad>
  private var indices: ContiguousArray<GLushort>
  private var quadCount = 0
  private var quadsDirty = false
  private var forceUpdate = false

  public init(maxSprites: Int = 500) {
    self.maxSprites = maxSprites
    quads = .init(count: maxSprites, repeatedValue: TexturedQuad())
    indices = .init(count: maxSprites * 6, repeatedValue: 0)
    setUpQuads()
  }

  private func setUpQuads() {
    for t in 0..<maxSprites {
      let v = GLushort(t) * 4
      let i = t * 6

      indices[i + 0] = v + 0  // counter-clockwise!
      indices[i + 1] = v + 2
      indices[i + 2] = v + 1

      indices[i + 3] = v + 0
      indices[i + 4] = v + 3
      indices[i + 5] = v + 2
    }
  }

  // MARK: - Data Model
  
  public func add(sprite: Sprite) {
    insert(sprite, atIndex: sprites.count)
  }

  public func insert(sprite: Sprite, atIndex index: Int) {
    assert(sprites.find(sprite) == nil, "Array already contains object")
    sprites.insert(sprite, atIndex: index)
    sprite.needsRedraw = true
  }

  public func remove(sprite: Sprite) {
    assert(sprites.find(sprite) != nil, "Array does not contain object")

    /*
    // This is a small optimization so we don't have to recalculate all quads
    // whenever a single sprite is removed. Whether this is really worth it
    // remains to be seen. In a game where all sprites bounce around the entire
    // time, it probably isn't and you might as well use the forceUpdate flag.
    NSUInteger index = [_sprites indexOfObject:sprite];
    NSUInteger count = [_sprites count] - 1;
    if (count > 0 && index < count) {
      memmove(_quads + index, _quads + index + 1, (count - index) * sizeof(PPTexturedQuad));
    }
    */

    sprites.removeObject(sprite)
    forceUpdate = true
  }

  public func removeAllSprites() {
    sprites.removeAll()
    forceUpdate = true
  }

  /*! Call this whenever you change the drawOrder property of the sprites. */
  public func sortSpritesByDrawOrder() {
    sprites.sortInPlace { $0.drawOrder <= $1.drawOrder }
    forceUpdate = true
  }

  // MARK: - Rendering

  public func update(dt: Float) {
    for sprite in sprites {
      sprite.update(dt)
    }
  }

  public func render(context: RenderContext) {
    updateQuads()
    drawSprites(context)
  }

  private func updateQuads() {
    quadCount = 0

    for sprite in sprites {
      // Does the quad for this sprite need to be updated?
      if forceUpdate || sprite.needsRedraw {
        sprite.needsRedraw = false
        quadsDirty = true
        quads[quadCount] = sprite.texturedQuad
        debug.dirtyCount += 1
      }

      // Note: even if a sprite does not need to be updated, we still need to
      // include its quad because we still need to draw it.
      quadCount += 1

      // Because the indices array is precalculated, we shouldn't use more
      // quads than we have room for.
      if quadCount == maxSprites { break }
    }

    forceUpdate = false
  }

  private func drawSprites(context: RenderContext) {
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

    glUniformMatrix4fv(GLint(shaderProgram.uniforms.matrix), 1, GLboolean(GL_FALSE), m)

    glEnableVertexAttribArray(shaderProgram.attributes.position)
    glEnableVertexAttribArray(shaderProgram.attributes.color)
    glEnableVertexAttribArray(shaderProgram.attributes.texCoord)

    if let texture = texture {
      glBlendFunc(texture.premultipliedAlpha ? GLenum(GL_ONE) : GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
      glBindTexture(GLenum(GL_TEXTURE_2D), texture.name)
    }

    quads.withUnsafeBufferPointer { qbuf in
      let pointer = UnsafePointer<UInt8>(qbuf.baseAddress)
      let stride = GLsizei(sizeof(TexturedVertex))

      glVertexAttribPointer(shaderProgram.attributes.position, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, pointer)
      glVertexAttribPointer(shaderProgram.attributes.texCoord, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, pointer + 8)
      glVertexAttribPointer(shaderProgram.attributes.color, 4, GLenum(GL_UNSIGNED_BYTE), GLboolean(GL_TRUE), stride, pointer + 16)

      indices.withUnsafeBufferPointer { ibuf in
        glDrawElements(GLenum(GL_TRIANGLES), Int32(quadCount) * 6, GLenum(GL_UNSIGNED_SHORT), ibuf.baseAddress)
      }
    }

    debug.drawCalls += 1
    debug.triangleCount += quadCount * 2

    glDisableVertexAttribArray(shaderProgram.attributes.texCoord)
    glDisableVertexAttribArray(shaderProgram.attributes.color)
    glDisableVertexAttribArray(shaderProgram.attributes.position)

    glBindTexture(GLenum(GL_TEXTURE_2D), 0)

    logOpenGLError()
  }
}
