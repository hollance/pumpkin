import simd

/* 
  These protocols describe the properties of an object that can be used in
  a tween. They're split up into different protocols because a Node, for 
  example, does not have a color. But a Sprite does not have an angle, etc.
*/

public protocol Tweenable: class {
}

public protocol PositionTweenable: Tweenable {
  var position: float2 { get set }
}

public protocol ScaleTweenable: Tweenable {
  var scale: float2 { get set }
}

public protocol AngleTweenable: Tweenable {
  var angle: Float { get set }
}

public protocol ColorTweenable: Tweenable {
  var color: float4 { get set }
}

public protocol AlphaTweenable: Tweenable {
  var alpha: Float { get set }
}
