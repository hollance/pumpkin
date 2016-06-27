//import simd
import GLKit

/*
 * Visual that can draw arbitrary triangles.
 */
public class Shape: Visual, Renderer {
  public weak var node: Node?
  public var needsRedraw: Bool = false
  public var hidden: Bool = false

  // TODO: a shape doesn't use these properties from Visual!
  public var anchorPoint = GLKVector2Make(0.5, 0.5)//float2(0.5, 0.5)
  public var flipX: Bool = false
  public var flipY: Bool = false
  public var contentSize = GLKVector2Make(0, 0)  //float2(0, 0)
  public var texCoords = GLKVector4Make(0, 0, 1, 1)  //float4(0, 0, 1, 1)

  public init() {
  }

  public func update(dt: Float) {
    // do nothing
  }

  public func render(context: RenderContext) {
    // do nothing
  }
}
