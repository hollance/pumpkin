import simd

/*! Base class for a visual that can draw arbitrary triangles. */
public class Shape: Visual, Renderer {
  public weak var node: Node?
  public var needsRedraw: Bool = false
  public var hidden: Bool = false

  // TODO: a shape doesn't use these properties from Visual!
  public var anchorPoint = float2(0.5, 0.5)
  public var flipX: Bool = false
  public var flipY: Bool = false
  public var contentSize = float2.zero
  public var texCoords = float4(0, 0, 1, 1)

  public init() { }

  public func update(dt: Float) {
    // subclass should implement this
  }

  public func render(context: RenderContext) {
    // subclass should implement this
  }
}
