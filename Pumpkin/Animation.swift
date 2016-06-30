/*!
  An animation of successive sprite frames.

  This object does not keep state, so you can add it to multiple sprites.
*/
public struct Animation {
  public var spriteFrames: [SpriteFrame] = []
  public var timePerFrame: Float = 0

  /*!
    If restoreOriginalFrame is true, then the sprite reverts to the original
    non-animated sprite frame; if false, the sprite remains on the last frame
    of the animation. The default is true.

    Note: if the animation is stopped prematurely, the original un-animated
    sprite frame is always restored.
  */
  public var restoreOriginalFrame = true

  public var loops = -1   // -1 is forever

  public init() { }
}
