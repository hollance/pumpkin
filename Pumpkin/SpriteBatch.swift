//import simd
import GLKit
import OpenGLES

/*
 * Draws a set of sprites that all share the same texture in a single draw call.
 *
 * Note: To draw placeholder sprites, set texture to nil and the shader program
 * to the colored shader.
 */
public class SpriteBatch: Renderer {
  public var texture: Texture?

//#if PP_USE_VBO
//	GLuint _vertexBuffer;
//	GLuint _indexBuffer;
//	#if PP_USE_VAO
//	GLuint _VAOname;
//	#endif
//#elif PP_USE_VBO_INDICES
//	GLuint _indexBuffer;
//#endif

  private var maxSprites: Int
  private(set) public var sprites: [Sprite] = []
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

//#if PP_USE_VBO
//
//	glGenBuffers(1, &_vertexBuffer);
//	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
//	glBufferData(GL_ARRAY_BUFFER, quadsSize, _quads, GL_DYNAMIC_DRAW);
//
//	glGenBuffers(1, &_indexBuffer);
//	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
//	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indicesSize, _indices, GL_STATIC_DRAW);
//
//	free(_indices), _indices = NULL;  // no longer need these
//
//	glBindBuffer(GL_ARRAY_BUFFER, 0);
//	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
//
//	#if PP_USE_VAO
//	[self setUpVAO];
//	#endif
//
//#elif PP_USE_VBO_INDICES
//
//	glGenBuffers(1, &_indexBuffer);
//	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
//	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indicesSize, _indices, GL_STATIC_DRAW);
//	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
//
//	free(_indices), _indices = NULL;  // no longer need these
//
//#endif
  }

/*
#if PP_USE_VBO && PP_USE_VAO
- (void)setUpVAO
{
	// With a Vertex Array Object (VAO) you no longer have to call
	// glVertexAttribPointer() before drawing, but simply bind the
	// vertex array and then do the draw call.

	glGenVertexArraysOES(1, &_VAOname);
	glBindVertexArrayOES(_VAOname);

	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);

	glEnableVertexAttribArray(PPShaderAttributePosition);
	glEnableVertexAttribArray(PPShaderAttributeTexCoord);
	glEnableVertexAttribArray(PPShaderAttributeColor);

	const GLsizei stride = sizeof(PPTexturedVertex);

	glVertexAttribPointer(PPShaderAttributePosition, 2, GL_FLOAT, GL_FALSE, stride, (const GLvoid *)offsetof(PPTexturedVertex, position));
	glVertexAttribPointer(PPShaderAttributeTexCoord, 2, GL_FLOAT, GL_FALSE, stride, (const GLvoid *)offsetof(PPTexturedVertex, texCoord));
	glVertexAttribPointer(PPShaderAttributeColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, stride, (const GLvoid *)offsetof(PPTexturedVertex, color));

	glBindVertexArrayOES(0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}
#endif

- (void)dealloc
{
#if PP_USE_VBO
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
#endif

#if PP_USE_VAO
	glDeleteVertexArraysOES(1, &_VAOname);
#endif

#if PP_USE_VBO_INDICES
    glDeleteBuffers(1, &_indexBuffer);
#endif

	free(_quads);
	free(_indices);
}
*/

  // MARK: - Data model
  
  public func add(sprite: Sprite) {
    insert(sprite, atIndex: sprites.count)
  }

  public func insert(sprite: Sprite, atIndex index: Int) {
    //PPAssert(![_sprites containsObject:sprite], @"Array already contains object");
    sprites.insert(sprite, atIndex: index)
    sprite.needsRedraw = true
  }

  public func remove(sprite: Sprite) {
    //PPAssert([_sprites containsObject:sprite], @"Array does not contain object");
    //NSUInteger index = [_sprites indexOfObject:sprite];

    sprites.removeObject(sprite)

  /*
    // This is a small optimization so we don't have to recalculate all quads
    // whenever a single sprite is removed. Whether this is really worth it
    // remains to be seen. In a game where all sprites bounce around the entire
    // time, it probably isn't and you might as well use the _forceUpdate flag.
    NSUInteger count = [_sprites count];
    if (count > 0 && index < count)
    {
      memmove(_quads + index, _quads + index + 1, (count - index) * sizeof(PPTexturedQuad));
    }
  */

    forceUpdate = true
  }

  public func removeAllSprites() {
    sprites.removeAll()
    forceUpdate = true
  }

  /* Call this whenever you change the drawOrder property of the sprites. */
  public func sortSpritesByDrawOrder() {
    sprites.sortInPlace { sprite1, sprite2 in
      sprite1.drawOrder <= sprite2.drawOrder
    }
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
      if forceUpdate || sprite.needsRedraw {
        //PPLog(@"dirty %@ (%@)", sprite.node.name, NSStringFromGLKVector2(sprite.node.position));

        sprite.needsRedraw = false
        quadsDirty = true
        quads[quadCount] = sprite.texturedQuad

        ppDirtyCount += 1
      }

      quadCount += 1
      if quadCount == maxSprites { break }
    }

    forceUpdate = false

    //print("Quad count: \(quadCount)")
  }

  private func drawSprites(context: RenderContext) {
    let shaderProgram: ShaderProgram
    if texture != nil {
      shaderProgram = context.texturedShader
    } else {
      shaderProgram = context.coloredShader
    }

    //print("Drawing sprites \(sprites.count), \(quadCount)")

    glUseProgram(shaderProgram.programName)

    // TODO: there must be an easier way to use float4x4's elements directly...
//    var m = [Float](count: 16, repeatedValue: 0)
//    for i in 0..<4 {
//      for j in 0..<4 {
//        m[i + j*4] = context.matrix[i, j]
//      }
//    }

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

    if let texture = texture {
      glBlendFunc(texture.premultipliedAlpha ? GLenum(GL_ONE) : GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
      glBindTexture(GLenum(GL_TEXTURE_2D), texture.name)
    }

//  #if PP_USE_VBO
//
//    #if !PP_USE_VAO
//    const GLsizei stride = sizeof(PPTexturedVertex);
//
//    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
//
//    glVertexAttribPointer(PPShaderAttributePosition, 2, GL_FLOAT, GL_FALSE, stride, (const GLvoid *)offsetof(PPTexturedVertex, position));
//    glVertexAttribPointer(PPShaderAttributeTexCoord, 2, GL_FLOAT, GL_FALSE, stride, (const GLvoid *)offsetof(PPTexturedVertex, texCoord));
//    glVertexAttribPointer(PPShaderAttributeColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, stride, (const GLvoid *)offsetof(PPTexturedVertex, color));
//    #endif
//
//    if (_quadsDirty)
//    {
//      glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
//      glBufferSubData(GL_ARRAY_BUFFER, 0, _quadCount * sizeof(PPTexturedQuad), _quads);
//      glBindBuffer(GL_ARRAY_BUFFER, 0);
//      _quadsDirty = NO;
//    }
//
//    #if PP_USE_VAO
//    glBindVertexArrayOES(_VAOname);
//    #endif
//
//    glDrawElements(GL_TRIANGLES, _quadCount * 6, GL_UNSIGNED_SHORT, 0);
//
//    #if PP_USE_VAO
//    glBindVertexArrayOES(0);
//    #else
//    glBindBuffer(GL_ARRAY_BUFFER, 0);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
//    #endif
//
//  #elif PP_USE_VBO_INDICES
//
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
//
//    const GLvoid *pointer = _quads;
//    const GLsizei stride = sizeof(PPTexturedVertex);
//
//    glVertexAttribPointer(PPShaderAttributePosition, 2, GL_FLOAT, GL_FALSE, stride, pointer + offsetof(PPTexturedVertex, position));
//    glVertexAttribPointer(PPShaderAttributeTexCoord, 2, GL_FLOAT, GL_FALSE, stride, pointer + offsetof(PPTexturedVertex, texCoord));
//    glVertexAttribPointer(PPShaderAttributeColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, stride, pointer + offsetof(PPTexturedVertex, color));
//
//    glDrawElements(GL_TRIANGLES, _quadCount * 6, GL_UNSIGNED_SHORT, 0);
//
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
//
//  #else

//    print("--------------------")
//    for q in 0..<quadCount {
//      print("QUAD \(q):\n")
//      print(quads[q])
//    }

    quads.withUnsafeBufferPointer { buf in
      let pointer = UnsafePointer<UInt8>(buf.baseAddress)
      let stride = GLsizei(sizeof(TexturedVertex))

      glVertexAttribPointer(ShaderAttributes.position.rawValue, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, pointer /*+ offsetof(TexturedVertex, position)*/)
      glVertexAttribPointer(ShaderAttributes.texCoord.rawValue, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, pointer + 8 /*offsetof(TexturedVertex, texCoord)*/)
      glVertexAttribPointer(ShaderAttributes.color.rawValue, 4, GLenum(GL_UNSIGNED_BYTE), GLboolean(GL_TRUE), stride, pointer + 16 /*offsetof(TexturedVertex, color)*/)

      indices.withUnsafeBufferPointer { ibuf in
        glDrawElements(GLenum(GL_TRIANGLES), Int32(quadCount) * 6, GLenum(GL_UNSIGNED_SHORT), ibuf.baseAddress)
      }
    }

//  #endif

    ppDrawCalls += 1
    ppTriangleCount += quadCount * 2

    glDisableVertexAttribArray(ShaderAttributes.texCoord.rawValue)
    glDisableVertexAttribArray(ShaderAttributes.color.rawValue)
    glDisableVertexAttribArray(ShaderAttributes.position.rawValue)

    glBindTexture(GLenum(GL_TEXTURE_2D), 0)

    PPLogGLError()  
  }
}
