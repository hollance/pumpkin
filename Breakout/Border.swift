//import simd
import GLKit
import Pumpkin

let BorderThickness: Float = 20

class Border: Shape {
  var color = GLKVector4Make(1, 1, 1, 1) //float4(1, 1, 1, 1)

  var length: Float = 0 {
    didSet {
      vertices[0].position = GLKVector2Make(0, 0)
      vertices[1].position = GLKVector2Make(0, length)
      vertices[2].position = GLKVector2Make(BorderThickness, 0)
      vertices[3].position = GLKVector2Make(BorderThickness, length)
    }
  }

  private var vertices: [ColoredVertex] = .init(count: 4, repeatedValue: ColoredVertex())
  private var transformedVertices: [ColoredVertex] = .init(count: 4, repeatedValue: ColoredVertex())
  private var indices: [GLushort] = [0, 1, 2, 3]

  override func render(context: RenderContext) {
    glUseProgram(context.coloredShader.programName);

    let uniforms = context.coloredShader.uniforms

    glEnableVertexAttribArray(ShaderAttributes.position.rawValue)
    glEnableVertexAttribArray(ShaderAttributes.color.rawValue)

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

      let matrix = GLKMatrix4Multiply(context.matrix, node!.transform)

      var m = [Float](count: 16, repeatedValue: 0)
      m[0] = matrix.m00
      m[1] = matrix.m01
      m[2] = matrix.m02
      m[3] = matrix.m03
      m[4] = matrix.m10
      m[5] = matrix.m11
      m[6] = matrix.m12
      m[7] = matrix.m13
      m[8] = matrix.m20
      m[9] = matrix.m21
      m[10] = matrix.m22
      m[11] = matrix.m23
      m[12] = matrix.m30
      m[13] = matrix.m31
      m[14] = matrix.m32
      m[15] = matrix.m33

      glUniformMatrix4fv(GLint(uniforms.matrix), 1, GLboolean(GL_FALSE), m)

      glVertexAttribPointer(ShaderAttributes.position.rawValue, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, pointer /*+ offsetof(PPColoredVertex, position)*/)
      glVertexAttribPointer(ShaderAttributes.color.rawValue, 4, GLenum(GL_UNSIGNED_BYTE), GLboolean(GL_TRUE), stride, pointer + 8 /*offsetof(PPColoredVertex, color)*/);

      glDrawElements(GLenum(GL_TRIANGLE_STRIP), 4, GLenum(GL_UNSIGNED_SHORT), indices)
    }

    glDisableVertexAttribArray(ShaderAttributes.position.rawValue)
    glDisableVertexAttribArray(ShaderAttributes.color.rawValue)

    ppDrawCalls += 1
    ppTriangleCount += 2
    ppDirtyCount += 1

    needsRedraw = false
  }
}
