import GLKit

/*
 * Manages PPTween objects.
 */
public class TweenPool {
  private var activeTweens: [Tween] = []
  private var recycledTweens: [String: [Tween]] = [:]

  public init() {
    activeTweens.reserveCapacity(10)
    //recycledTweens.reserveCapacity(10)
  }

  /*
   * This is the preferred way to obtain tween objects. It will try to recycle
   * old objects and only makes new ones if there are no recyclable tweens left.
   * This prevents the app from making tons of new instances all the time.
   */
  public func tweenOfType(type: Tween.Type) -> Tween {
    let key = NSStringFromClass(type)
    if var array = recycledTweens[key] {
      if array.count > 0 {
        let tween = array.removeLast()
        recycledTweens[key] = array     //TODO: Weird
        return tween
      }
    }
    return type.init()   // no recyclable tween found
  }

  public func moveFromTween() -> MoveFromTween {
    return tweenOfType(MoveFromTween) as! MoveFromTween
  }

  public func moveToTween() -> MoveToTween {
    return tweenOfType(MoveToTween) as! MoveToTween
  }

  public func rotateFromTween() -> RotateFromTween {
    return tweenOfType(RotateFromTween) as! RotateFromTween
  }

  public func rotateToTween() -> RotateToTween {
    return tweenOfType(RotateToTween) as! RotateToTween
  }

  public func scaleFromTween() -> ScaleFromTween {
    return tweenOfType(ScaleFromTween) as! ScaleFromTween
  }

  public func scaleToTween() -> ScaleToTween {
    return tweenOfType(ScaleToTween) as! ScaleToTween
  }

  public func tintTween() -> TintTween {
    return tweenOfType(TintTween) as! TintTween
  }

  public func fadeTween() -> FadeTween {
    return tweenOfType(FadeTween) as! FadeTween
  }

  private func recycleTween(tween: Tween) {
    let key = NSStringFromClass(tween.dynamicType)

    tween.prepareForReuse()

    if var array = recycledTweens[key] {
      array.append(tween)
      recycledTweens[key] = array   // TODO
    } else {
      recycledTweens[key] = [tween]
    }
  }

  /* Adds a new tween and starts it animating. */
  public func add(tween: Tween) {
    //PPAssert(![_activeTweens containsObject:tween], @"Array already contains object");

    activeTweens.append(tween)
    tween.start()
  }

  /*
   * Removes any tweens with the same name from the same target and adds the
   * new one. Even if finish is YES, the old tweens' completion blocks will not
   * be executed.
   */
  public func replace(tween: Tween, finish: Bool) {
    let oldTweens = tweensForTarget(tween.target!, withName: tween.name)
    remove(oldTweens, finish: finish)
    add(tween)
  }

  /* Removes the specified tween. */
  public func remove(tween: Tween, finish: Bool) {
    //PPAssert([_activeTweens containsObject:tween], @"Array does not contain object");

    if finish && !tween.isCompleted {
      tween.finish()
    }

    recycleTween(tween)
    activeTweens.removeObject(tween)
  }

  /* Removes one or more tweens. */
  public func remove(tweens: [Tween], finish: Bool) {
    //PPAssert(tweens != _activeTweens, @"Use removeAllTweensWithFinish: instead");

    for tween in tweens {
      remove(tween, finish: finish)
    }
  }

  /* Removes tweens from a specific target. */
  public func remove(forTarget target: Tweenable, withName name: String, finish: Bool) {
  	remove(tweensForTarget(target, withName: name), finish: finish)
  }

  /* Removes all active tweens. */
  public func removeAllTweensWithFinish(finish: Bool) {
    for tween in activeTweens {
      if finish && !tween.isCompleted {
        tween.finish()
      }
      recycleTween(tween)
    }
    activeTweens.removeAll()
  }

  /* Moves all the tweens forward. */
  public func updateTweens(dt: Float) {
    var t = 0
    while t < activeTweens.count {
      let tween = activeTweens[t]

      if tween.isCompleted {
        if let block = tween.completionBlock {
          block()
        }

        recycleTween(tween)
        activeTweens.removeAtIndex(t)
      }
      else {
        tween.update(dt)
        t += 1
      }
    }
  }

  /* Returns a read-only list of all currently active tweens. */
  public var allTweens: [Tween] {
    return activeTweens
  }

  /* For retrieving the tweens set on a target. */
  public func tweensForTarget(target: Tweenable) -> [Tween] {
    var array: [Tween] = []

    for tween in activeTweens {
      if tween.target! === target {
        array.append(tween)
      }
    }

    return array
  }

  public func tweensForTarget(target: Tweenable, withName name: String) -> [Tween] {
    var array: [Tween] = []

    for tween in activeTweens {
      if tween.target! === target && tween.name == name {
        array.append(tween)
      }
    }

    return array
  }

  public func tweensForTarget(target: Tweenable, ofType type: Tween.Type) -> [Tween] {
    var array: [Tween] = []

    for tween in activeTweens {
      if tween.target! === target && tween.dynamicType == type {
        array.append(tween)
      }
    }

    return array
  }

  /* Empties the pool of recycled tweens. */
  public func flushRecycledTweens() {
    recycledTweens.removeAll()
  }
}

extension TweenPool {
  /**
   * Creates a screen shake animation.
   *
   * @param amount The vector by which the node is displaced.
   * @param oscillations The number of oscillations. 10 is a good value.
   */
  public func screenShakeWithNode(node: Node, amount: GLKVector2, oscillations: Int, duration: Float) -> Tween {

    // Note: For optimal performance, you should create the shake function just
    // once and cache it. In the current implementation it allocates a new block
    // instance every time you start a screen shake.

    let tween = moveFromTween()
    tween.target = node
    tween.amount = amount
    tween.duration = duration
    tween.timingFunction = CreateShakeFunction(oscillations)
    add(tween)
    return tween
  }

  /**
   * Creates a screen rotation animation.
   *
   * @param angle The angle in degrees.
   * @param oscillations The number of oscillations. 10 is a good value.
   *
   * You usually want to apply this to a pivot node that is centered in the scene.
   */
  public func screenTumbleWithNode(node: Node, angle: Float, oscillations: Int, duration: Float) -> Tween {
    let tween = rotateFromTween()
    tween.target = node
    tween.amount = angle
    tween.duration = duration
    tween.timingFunction = CreateShakeFunction(oscillations)
    add(tween)
    return tween
  }

  /**
   * Creates a screen zoom animation.
   *
   * @param amount How much to scale the node in the X and Y directions.
   * @param oscillations The number of oscillations. 10 is a good value.
   *
   * You usually want to apply this to a pivot node that is centered in the scene.
   */
  public func screenZoomWithNode(node: Node, amount: GLKVector2, oscillations: Int, duration: Float) -> Tween {
    let tween = scaleFromTween()
    tween.target = node
    tween.amount = amount
    tween.duration = duration
    tween.timingFunction = CreateShakeFunction(oscillations)
    add(tween)
    return tween
  }
}
