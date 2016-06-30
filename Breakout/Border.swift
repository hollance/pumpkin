import simd
import Pumpkin

let BorderThickness: Float = 20

class Border: Shape {
  var color = float4(1, 1, 1, 1)

  var length: Float = 0 {
    didSet {
      vertices[0].position = float2(0, 0)
      vertices[1].position = float2(0, length)
      vertices[2].position = float2(BorderThickness, 0)
      vertices[3].position = float2(BorderThickness, length)
    }
  }

  private var vertices: [ColoredVertex] = .init(count: 4, repeatedValue: ColoredVertex())
  private var transformedVertices: [ColoredVertex] = .init(count: 4, repeatedValue: ColoredVertex())
  private var indices: [GLushort] = [0, 1, 2, 3]

  override func render(context: RenderContext) {
    let shaderProgram: ShaderProgram = context.coloredShader

    glUseProgram(shaderProgram.programName)

    let uniforms = shaderProgram.uniforms

    glEnableVertexAttribArray(shaderProgram.attributes.position)
    glEnableVertexAttribArray(shaderProgram.attributes.color)

    for t in 0..<4 {
      var vertex = vertices[t]

      vertex.r = UInt8(color.x * 255)
      vertex.g = UInt8(color.y * 255)
      vertex.b = UInt8(color.z * 255)
      vertex.a = UInt8(color.w * 255)

      transformedVertices[t] = vertex
    }

    transformedVertices.withUnsafeBufferPointer { buf in
      let pointer = UnsafePointer<UInt8>(buf.baseAddress)
      let stride = GLsizei(sizeof(ColoredVertex))

      let matrix = context.matrix * node!.transform
      glUniformMatrix4fv(GLint(uniforms.matrix), 1, GLboolean(GL_FALSE), matrix.openGLMatrix)

      glVertexAttribPointer(shaderProgram.attributes.position, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, pointer)
      glVertexAttribPointer(shaderProgram.attributes.color, 4, GLenum(GL_UNSIGNED_BYTE), GLboolean(GL_TRUE), stride, pointer + 8)

      glDrawElements(GLenum(GL_TRIANGLE_STRIP), 4, GLenum(GL_UNSIGNED_SHORT), indices)
    }

    glDisableVertexAttribArray(shaderProgram.attributes.position)
    glDisableVertexAttribArray(shaderProgram.attributes.color)

    debug.drawCalls += 1
    debug.triangleCount += 2
    debug.dirtyCount += 1

    needsRedraw = false
  }
}
