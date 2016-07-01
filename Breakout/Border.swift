import Foundation
import simd
import Pumpkin

class Border: Shape {
  static let thickness: Float = 20

  private let bounceDuration: Float = 0.8
  private let bounceDistance: Float = 20.0
  private let numberOfSubdivisions = 4

  var color = float4(1, 1, 1, 1) {
    didSet {
      for t in 0..<vertices.count {
        vertices[t].r = UInt8(color.x * 255)
        vertices[t].g = UInt8(color.y * 255)
        vertices[t].b = UInt8(color.z * 255)
        vertices[t].a = UInt8(color.w * 255)
      }
    }
  }

  var length: Float = 0 {
    didSet {
      restoreOriginalBorder()
    }
  }

  private var spot: Float = 0
  private var animating = false
  private var elapsed: Float = 0
  private var pointCount: Int
  private var points: [float2]
  private var vertexCount = 0

  private var vertices: [ColoredVertex]
  private var indices: [GLushort]

  override init() {
    pointCount = 1 + Int(pow(2, Float(numberOfSubdivisions + 1)))
    points = .init(count: pointCount, repeatedValue: float2())

    // Each "segment" is made up of two triangles and 4 vertices and 4 indices,
    // but we re-use two of the vertices for the next segment.
    // For N segments we need N*2 triangles, N*2+2 vertices, and N*4 indices.

    vertices = .init(count: pointCount * 2, repeatedValue: ColoredVertex())
    indices = .init(count: (pointCount - 1) * 4, repeatedValue: 0)

    for t in 0..<pointCount - 1 {
      let v = GLushort(t) * 2
      let i = t * 4
      indices[i + 0] = v + 0
      indices[i + 1] = v + 2
      indices[i + 2] = v + 1
      indices[i + 3] = v + 3
    }

    super.init()
  }

  func restoreOriginalBorder() {
    // This restores the border to just a single quad.
    vertices[0].position = float2(0, 0)
    vertices[1].position = float2(Border.thickness, 0)
    vertices[2].position = float2(0, length)
    vertices[3].position = float2(Border.thickness, length)
    vertexCount = 4
  }

  func animateHit(atSpot spot: Float) {
    self.spot = spot
    animating = true
    elapsed = 0

    /* We calculate an array of vectors that describe the points that make up
       the border's segments. These are not the vertices yet. In update(), we
       convert the points into the final vertices that describe the triangles.
       We *could* combine these two steps, but the current approach is a bit
       simpler to understand, I find. */

    let startPoint = float2(0, 0)
    let midPoint = float2(bounceDistance, spot)
    let endPoint = float2(0, length)

    let midPointIndex = (pointCount - 1)/2

    points[0] = startPoint
    points[midPointIndex] = midPoint
    points[pointCount - 1] = endPoint

    subdivideBetween(startIndex: 0, endIndex: midPointIndex)
    subdivideBetween(startIndex: pointCount - 1, endIndex: midPointIndex)
  }

  private func subdivideBetween(startIndex startIndex: Int, endIndex: Int) {
    if abs(endIndex - startIndex) == 1 { return }  // no more subdivisions left

    let newIndex = (startIndex + endIndex)/2
    let factor = Float(newIndex)*2/Float(pointCount - 1)
    let curvature = factor * (2 - factor)

    let startPoint = points[startIndex]
    let endPoint = points[endIndex]

    let newPoint = float2(bounceDistance * curvature, (startPoint.y + endPoint.y)/2)
    points[newIndex] = newPoint

    subdivideBetween(startIndex: startIndex, endIndex: newIndex)
    subdivideBetween(startIndex: newIndex, endIndex: endIndex)
  }

  override func update(dt: Float) {
    if animating {
      if elapsed > bounceDuration {
        animating = false
        restoreOriginalBorder()
        return
      }

      let f = elapsed / bounceDuration
      let t = sin(f * π * 8) * 0.5 * (1 - f) * (1 - f) + 0.5
      elapsed += dt

      var lastPoint = points[0]
      vertexCount = 0
      vertices[vertexCount + 0].position = lastPoint
      vertices[vertexCount + 1].position = float2(lastPoint.x + Border.thickness, lastPoint.y)
      vertexCount += 2

      for i in 1..<pointCount-1 {
        var point = points[i]
        point = mix(point, float2(-point.x, point.y), t: t)  // lerp

        vertices[vertexCount + 0].position = point
        vertices[vertexCount + 1].position = float2(point.x + Border.thickness, point.y)
        vertexCount += 2

        lastPoint = point
      }

      let endPoint = points[pointCount - 1]
      vertices[vertexCount + 0].position = endPoint
      vertices[vertexCount + 1].position = float2(endPoint.x + Border.thickness, endPoint.y)
      vertexCount += 2
    }
  }

  override func render(context: RenderContext) {
    let shaderProgram: ShaderProgram = context.coloredShader

    glUseProgram(shaderProgram.programName)

    let uniforms = shaderProgram.uniforms

    glEnableVertexAttribArray(shaderProgram.attributes.position)
    glEnableVertexAttribArray(shaderProgram.attributes.color)

    vertices.withUnsafeBufferPointer { buf in
      let pointer = UnsafePointer<UInt8>(buf.baseAddress)
      let stride = GLsizei(sizeof(ColoredVertex))

      let matrix = context.matrix * node!.transform
      glUniformMatrix4fv(GLint(uniforms.matrix), 1, GLboolean(GL_FALSE), matrix.openGLMatrix)

      glVertexAttribPointer(shaderProgram.attributes.position, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), stride, pointer)
      glVertexAttribPointer(shaderProgram.attributes.color, 4, GLenum(GL_UNSIGNED_BYTE), GLboolean(GL_TRUE), stride, pointer + 8)

      let indexCount = vertexCount*2 - 4
      glDrawElements(GLenum(GL_TRIANGLE_STRIP), GLsizei(indexCount), GLenum(GL_UNSIGNED_SHORT), indices)
    }

    glDisableVertexAttribArray(shaderProgram.attributes.position)
    glDisableVertexAttribArray(shaderProgram.attributes.color)

    debug.drawCalls += 1
    debug.triangleCount += vertexCount - 2
    debug.dirtyCount += 1

    needsRedraw = false
  }
}
