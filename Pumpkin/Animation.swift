/*
 * An animation of successive sprite frames.
 *
 * This object does not keep state, so you can add it to multiple sprites.
 */
public class Animation {

  public var spriteFrames: [SpriteFrame] = []
  public var timePerFrame: Float = 0

  /*
   * If restoreOriginalFrame is YES, then the sprite reverts to the original
   * non-animated sprite frame; if NO, the sprite remains on the last frame of
   * the animation. The default is YES.
   *
   * Note: if the animation is stopped prematurely, the original un-animated
   * sprite frame is always restored.
   */
  public var restoreOriginalFrame = true

  public var loops = -1   // -1 is forever
}
