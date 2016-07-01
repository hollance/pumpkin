import Foundation
import simd

public typealias TweenCompletionBlock = (Void) -> Void

/*!
  Abstract base class for all tweens.

  A tween is simply something that changes over time, usually a lerp of some
  scalar or vector property. Tweens are not necessarily associated with nodes,
  although they will usually work on a node or on its visual.
*/
public class Tween {
  /*! The object that you're tweening. This is a weak reference, so the tween 
      will automatically stop when the target is deallocated elsewhere. */
  public weak var target: Tweenable?

  /*! The completion block is executed when the tween finishes. May be nil. */
  public var completionBlock: TweenCompletionBlock?

  /*! You can look up tweens by name. Also handy for debugging. */
  public var name = ""

  public required init() { }

  deinit {
    print("deinit \(self)")
  }

  /*! Called just before the tween begins animating. */
  internal func start() {
  	// subclass should implement this
  }

  /*! Called every frame to move the tween forward. */
  internal func update(dt: Float) {
    // subclass should implement this
  }

  /*!
    Moves the tween to the end state. This is useful when you want to remove
    a tween before it is completed, for example to replace it with a new tween.
    Without calling finish, the target would end up in a halfway state because
    the first tween didn't make it all the way to the end.

    This calls the tween's completion block, if it has one.

    Note: When you remove a tween before it is finished without calling this
    method, its completion block will never be called.
  */
  internal func finish() {
    // subclass should implement this
  }

  /*! Like finish but with the option of not calling the completion block. */
  internal func finishWithCompletion(flag: Bool) {
    if !flag {
      completionBlock = nil
    }
    finish()
  }

  /*! Whether the tween is completed. True if the elapsed time is equal to the
      duration, or when the target is deallocated. */
  internal var isCompleted: Bool {
    // subclass should implement this
    return true
  }

  /*! Called by the TweenPool when it's about to recycle this tween. */
  internal func prepareForReuse() {
    target = nil
    completionBlock = nil
    name = ""
  }
}

extension Tween: CustomStringConvertible {
  public var description: String {
    return "tween \(name)"
  }
}

/*! Base class for tweens that animate between a single start and end value. */
public class BasicTween: Tween {
  /*! Duration in seconds. This does not include the time for the delay. */
  public var duration: Float = 0

  /*! Delay in seconds before the tween begins. */
  public var delay: Float = 0

  /*! What sort of easing to apply. Default is linear timing. */
  public var timingFunction = TimingFunctionLinear

  /*! For keyframe animations; if true, does not put the target in the start
      position until the delay is over. */
  public var waitUntilAfterDelay = false

  private var completed = false
  private var delayElapsed: Float = 0
  private var elapsed: Float = 0

  internal override func update(dt: Float) {
    assert(target != nil, "Animation should not run if target is nil")
    assert(!completed, "Animation should not run if it is already completed")

    var t: Float = 0
    if delayElapsed < self.delay {   // waiting for tween to start
      t = 0
      delayElapsed += dt

      // If a delay is set, the tween is already moved to the starting state
      // (at t = 0) during the delay. That is usually what you want, except
      // for the second and next tweens in keyframe sequences, so this flag
      // lets you skip that.
      if waitUntilAfterDelay { return }
    }
    else if elapsed < self.duration {   // performing tween
      t = elapsed / self.duration
      elapsed += dt
    }
    else {       // done
      t = 1.0
      completed = true
    }

    step(timingFunction(t))
  }

  internal override func finish() {
    if !isCompleted {
      step(timingFunction(1))
      completed = true
    }
  }

  internal override var isCompleted: Bool {
    return target == nil || completed
  }

  internal override func prepareForReuse() {
    super.prepareForReuse()
    duration = 0
    delay = 0
    timingFunction = TimingFunctionLinear
    completed = false
    delayElapsed = 0
    elapsed = 0
  }

  internal func step(t: Float) {
    // subclass should implement this
  }
}

/*!
  Tween that changes the position of the target.

  It immediately adds amount to the target's position and then reduces that
  back to 0 over time.
*/
public class MoveFromTween : BasicTween {
  public var amount = float2.zero
  private var previousValue = float2.zero

  internal override func start() {
    previousValue = float2.zero
  }

  internal override func step(t: Float) {
    // Note: The lerp is "s + (0 - s)t" which simplifies to "s(1 - t)".
    let value = amount * (1 - t)
    let diff = value - previousValue
    previousValue = value
    (target as? PositionTweenable)?.position += diff
  }
}

/*!
  Tween that changes the position of the target.

  The start value is 0. Over time the amount of movement is added to it.
*/
public class MoveToTween : BasicTween {
  public var amount = float2.zero
  private var previousValue = float2.zero

  internal override func start() {
    previousValue = float2.zero
  }

  internal override func step(t: Float) {
    // Note: The lerp is "0 + (e - 0)t" which simplifies to "e*t".
    let value = amount * t
    let diff = value - previousValue
    previousValue = value
    (target as? PositionTweenable)?.position += diff
  }
}

/*!
  Tween that changes the rotation angle of the target.

  It immediately adds amount to the target's current rotation angle and then
  reduces that back to 0 over time.
*/
public class RotateFromTween : BasicTween {
  public var amount: Float = 0
  public var previousValue: Float = 0

  internal override func start() {
    previousValue = 0
  }

  internal override func step(t: Float) {
    // Note: The lerp is "s + (0 - s)t" which simplifies to "s(1 - t)".
    let value = amount * (1 - t)
    let diff = value - previousValue
    previousValue = value
    (target as? AngleTweenable)?.angle += diff
  }
}

/*!
  Tween that changes the rotation angle of the target.

  The start value is 0. Over time the amount of rotation is added to it.
*/
public class RotateToTween : BasicTween {
  public var amount: Float = 0
  public var previousValue: Float = 0

  internal override func start() {
    previousValue = 0
  }

  internal override func step(t: Float) {
    // Note: The lerp is "0 + (e - 0)t" which simplifies to "e*t".
    let value = amount * t
    let diff = value - previousValue
    previousValue = value
    (target as? AngleTweenable)?.angle += diff
  }
}

/*!
  Tween that changes the scale of the target.

  It immediately "adds" to the target's current scale and then reduces that
  back to (1, 1) over time.
*/
public class ScaleFromTween : BasicTween {
  public var amount = float2.zero
  private var previousValue = float2.zero

  internal override func start() {
    previousValue = float2(1, 1)
  }

  internal override func step(t: Float) {
    // Note: The lerp is "s + (1 - s)*t", which simplifies to "t + s(1 - t)".
    let value = amount * (1 - t) + float2(t, t)
    let diff = value / previousValue
    previousValue = value
    (target as? ScaleTweenable)?.scale *= diff
  }
}

/*!
  Tween that changes the scale of the target.

  The start value is (1, 1); over time this increments (or decrements)
  to the amount.
*/
public class ScaleToTween : BasicTween {
  public var amount = float2.zero
  private var previousValue = float2.zero

  internal override func start() {
    previousValue = float2(1, 1)
  }

  internal override func step(t: Float) {
    // Note: The lerp is "1 + (e - 1)*t", which simplifies to "e*t + 1 - t".
    let value = amount * t + float2(1 - t)
    let diff = value / previousValue
    previousValue = value
    (target as? ScaleTweenable)?.scale *= diff
  }
}

/*!
  Tween that changes the color of the target.

  The endColor is usually the target's normal color. You need to specify it
  explicitly because another tween may also be changing the color at the same
  time, so the target's current color may not be the same as its normal color.

  Tint tweens overwrite each other's changes so if multiple tint tweens are
  active, only the most recent tween you added has any effect.
*/
public class TintTween : BasicTween {
  public var startColor = float4.zero
  public var endColor = float4.zero

  internal override func step(t: Float) {
    (target as? ColorTweenable)?.color = mix(startColor, endColor, t: t)
  }
}

/*!
  Tween that changes the transparency of the target.

  The endAlpha is usually the target's normal alpha. You need to specify it
  explicitly because another tween may also be changing the alpha at the same
  time, so the target's current alpha may not be the same as its normal alpha.

  Fade tweens overwrite each other's changes so if multiple fade tweens are
  active, only the most recent tween you added has any effect.
*/
public class FadeTween : BasicTween {
  public var startAlpha: Float = 0
  public var endAlpha: Float = 0

  internal override func step(t: Float) {
    (target as? AlphaTweenable)?.alpha = fclampf(flerpf(start: startAlpha, end: endAlpha, t: t), min: 0, max: 1)
  }
}
