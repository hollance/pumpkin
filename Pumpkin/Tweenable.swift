import simd

/*
 * Describes the properties of an object that can be used in a tween.
 */
public protocol Tweenable: class {

  // Implemented by PPNode

  /* The position of the node relative to its parent. */
  var position: float2 { get set }

  /* The scale of the node (and its children). */
  var scale: float2 { get set }

  /* The rotation angle of the node in degrees, clockwise. */
  var angle: Float { get set }

  // Implemented by PPSprite

  var color: float4 { get set }
  var alpha: Float { get set }
}
