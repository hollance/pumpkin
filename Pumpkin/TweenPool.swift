import simd

/*! Manages PPTween objects. */
public class TweenPool {
  private var recycledTweens: [String: [Tween]] = [:]

  /*! A read-only list of all currently active tweens. */
  private(set) public var activeTweens: [Tween] = []

  public init() {
  }

  /* This is the preferred way to obtain tween objects. It will try to recycle
     old objects and only makes new ones if there are no recyclable tweens left.
     This prevents the app from making tons of new instances all the time. */
  internal func tweenOfType(type: Tween.Type) -> Tween {
    let key = NSStringFromClass(type)
    if recycledTweens[key]?.count > 0 {
      return recycledTweens[key]!.removeLast()
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
    tween.prepareForReuse()

    let key = NSStringFromClass(tween.dynamicType)
    if recycledTweens[key] != nil {
      recycledTweens[key]!.append(tween)
    } else {
      recycledTweens[key] = [tween]
    }
  }

  /*! Adds a new tween and starts it animating. */
  public func add(tween: Tween) {
    assert(activeTweens.find(tween) == nil, "Array already contains object")
    activeTweens.append(tween)
    tween.start()
  }

  /*! Removes any tweens with the same name from the same target and adds the
      new one. Even if finish is true, the old tweens' completion blocks will
      not be executed. */
  public func replace(tween: Tween, finish: Bool) {
    let oldTweens = tweensForTarget(tween.target!, withName: tween.name)
    remove(oldTweens, finish: finish)
    add(tween)
  }

  /*! Removes the specified tween. */
  public func remove(tween: Tween, finish: Bool) {
    assert(activeTweens.find(tween) != nil, "Array does not contain object")

    if finish && !tween.isCompleted {
      tween.finish()
    }

    recycleTween(tween)
    activeTweens.removeObject(tween)
  }

  /*! Removes one or more tweens. */
  public func remove(tweens: [Tween], finish: Bool) {
    for tween in tweens {
      remove(tween, finish: finish)
    }
  }

  /*! Removes tweens from a specific target. */
  public func remove(forTarget target: Tweenable, withName name: String, finish: Bool) {
  	remove(tweensForTarget(target, withName: name), finish: finish)
  }

  /*! Removes all active tweens. */
  public func removeAllTweens(finish finish: Bool) {
    for tween in activeTweens {
      if finish && !tween.isCompleted {
        tween.finish()
      }
      recycleTween(tween)
    }
    activeTweens.removeAll()
  }

  /*! Moves all the tweens forward in time. */
  public func updateTweens(dt: Float) {
    var t = 0
    while t < activeTweens.count {
      let tween = activeTweens[t]
      if tween.isCompleted {
        tween.completionBlock?()
        recycleTween(tween)
        activeTweens.removeAtIndex(t)
      } else {
        tween.update(dt)
        t += 1
      }
    }
  }

  /*! Retrieves the tweens set on a target. */
  public func tweensForTarget(target: Tweenable) -> [Tween] {
    var array: [Tween] = []
    for tween in activeTweens {
      if tween.target! === target {
        array.append(tween)
      }
    }
    return array
  }

  /*! Retrieves the tweens set on a target. */
  public func tweensForTarget(target: Tweenable, withName name: String) -> [Tween] {
    var array: [Tween] = []
    for tween in activeTweens {
      if let tgt = tween.target where tgt === target && tween.name == name {
        array.append(tween)
      }
    }
    return array
  }

  /*! Retrieves the tweens set on a target. */
  public func tweensForTarget(target: Tweenable, ofType type: Tween.Type) -> [Tween] {
    var array: [Tween] = []
    for tween in activeTweens {
      if tween.target! === target && tween.dynamicType == type {
        array.append(tween)
      }
    }
    return array
  }

  /*! Empties the pool of recycled tweens. */
  public func flushRecycledTweens() {
    recycledTweens.removeAll()
  }
}

extension TweenPool {
  /*!
    Creates a screen shake animation.

    Parameters:
     - amount The vector by which the node is displaced.
     - oscillations The number of oscillations. 10 is a good value.
  */
  public func screenShake(node node: Node, amount: float2, oscillations: Int, duration: Float) -> Tween {
    // Note: For optimal performance, you should create the shake function
    // just once and cache it. In the current implementation it allocates a 
    // new closure instance every time you start a screen shake.
    let tween = moveFromTween()
    tween.target = node
    tween.amount = amount
    tween.duration = duration
    tween.timingFunction = CreateShakeFunction(oscillations)
    add(tween)
    return tween
  }

  /*!
    Creates a screen rotation animation.
   
    Parameters:
     - angle The angle in degrees.
     - oscillations The number of oscillations. 10 is a good value.

    You usually want to apply this to a pivot node that is centered in the scene.
  */
  public func screenTumble(node node: Node, angle: Float, oscillations: Int, duration: Float) -> Tween {
    let tween = rotateFromTween()
    tween.target = node
    tween.amount = angle
    tween.duration = duration
    tween.timingFunction = CreateShakeFunction(oscillations)
    add(tween)
    return tween
  }

  /*!
    Creates a screen zoom animation.
   
    Parameters:
     - amount How much to scale the node in the X and Y directions.
     - oscillations The number of oscillations. 10 is a good value.

    You usually want to apply this to a pivot node that is centered in the scene.
  */
  public func screenZoom(node node: Node, amount: float2, oscillations: Int, duration: Float) -> Tween {
    let tween = scaleFromTween()
    tween.target = node
    tween.amount = amount
    tween.duration = duration
    tween.timingFunction = CreateShakeFunction(oscillations)
    add(tween)
    return tween
  }
}
