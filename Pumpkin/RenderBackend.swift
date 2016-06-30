import simd

/*! Abstracts away the technology used to perform the actual drawing. */
internal protocol RenderBackend: class {
  var viewportSize: float2 { get }

  var clearColor: float4 { get set }
  var modelviewMatrix: float4x4  { get set }

  func update(dt: Float)
  func render(renderQueue: RenderQueue)
}
