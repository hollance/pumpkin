import simd

/*! Base class for a visual that can draw arbitrary triangles. */
public class Shape: Visual, Renderer {
  public weak var node: Node?
  public var needsRedraw: Bool = false
  public var hidden: Bool = false

  public init() { }

  public func update(dt: Float) {
    // subclass should implement this
  }

  public func render(context: RenderContext) {
    // subclass should implement this
  }
}
