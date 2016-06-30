/*! Describes something that can be added to the render queue. */
public protocol Renderer: class {

  /*! You can use this to move any animations forward. */
  func update(dt: Float)

  /*! Does the actual drawing with OpenGL or Metal. */
  func render(context: RenderContext)
}
