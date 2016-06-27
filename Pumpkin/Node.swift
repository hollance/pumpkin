//import simd
import GLKit

/*
 * Model object for something that is displayed on the screen.
 */
public class Node: Tweenable {

  public var position /*: float2 = .init(0, 0)*/ = GLKVector2Make(0, 0) {
    didSet { localTransformDirty = true }
  }

  public var scale /*: float2 = .init(1, 1)*/ = GLKVector2Make(1, 1) {
    didSet { localTransformDirty = true }
  }

  public var angle: Float = 0 {
    didSet { localTransformDirty = true }
  }



  // TODO: these don't belong here but in Sprite
  public var color = GLKVector4(v: (1, 1, 1, 1)) //: float4 = .init(1, 1, 1, 1)
  public var alpha: Float = 1.0



  /* The thing that gets drawn for this node, if any. */
  public var visual: Visual? {
    willSet {
      visual?.node = nil
    }
    didSet {
      visual?.node = self
      visual?.needsRedraw = true
    }
  }

//TODO: don't use optional here, force cast in get {} or fatalError() if not sprite
  /* Convenience property so you don't have to cast visual all the time. */
  public var sprite: Sprite? {
    get { return visual as? Sprite }
    //set { visual = sprite }
  }

//TODO: using node.shape = Border() doesn't seem to work? but assigning it to visual does...
  /* Convenience property so you don't have to cast visual all the time. */
  public var shape: Shape? {
    get { return visual as? Shape }
    //set { visual = shape }
  }

  /* For building the scene graph. */
  private(set) public weak var parent: Node?
  private(set) public var children: [Node] = []

  /* For debugging and finding nodes by name. */
  public var name = ""

  /* For identifying nodes by a numeric value. */
  public var tag = 0

  /* Any arbitrary object that you want to associate with this node. */
  public var userData: AnyObject?

  public init() {
  }

  deinit {
    print("deinit \(self)")
  }

  /*
   * The transform for this node. The transform of the parent has already been
   * applied to this, so it's in world coordinates.
   */
  private(set) public var transform = GLKMatrix4Identity// float4x4(1)

  /* The transform in object coordinates. */
  private var localTransform = GLKMatrix4Identity// float4x4(1)
  private var localTransformDirty = true

  // MARK: - Building the scene graph

  public func add(child: Node) {
    insert(child, atIndex: children.count)
  }

  public func insert(child: Node, atIndex index: Int) {
    assert(child.parent == nil, "Node already has parent")
    assert(children.find(child) == nil, "Node already contains child")

    children.insert(child, atIndex: index)
    child.parent = self
  }

  public func remove(child: Node) {
    if let index = children.find(child) {
      children.removeAtIndex(index)
      child.parent = nil
    }
  }

  public func remove(children list: [Node]) {
    for child in list {
      remove(child)
    }
  }

  public func removeAllChildren() {
    for child in children {
      child.parent = nil
    }
    children.removeAll()
  }

  public func removeFromParent() {
    parent?.remove(self)
  }

  // MARK: - Inspecting the scene graph

  public func childNode(withName name: String) -> Node? {
    for child in children {
      if child.name == name { return child }
    }
    return nil
  }

  public func childNode(withTag tag: Int) -> Node? {
    for child in children {
      if child.tag == tag { return child }
    }
    return nil
  }

  /*
  - (void)enumerateChildNodesWithName:(NSString *)name usingBlock:(void (^)(PPNode *node, BOOL *stop))block
  {
    BOOL stop = NO;
    for (PPNode *child in _children)
    {
      block(child, &stop);
      if (stop) return;
    }
  }
  */

  public func inParentHierarchy(other: Node) -> Bool {
    var p = parent
    while p != nil {
      if p === other { return true }
      p = p?.parent
    }
    return false
  }

  // MARK: - Transforms

  func calculateLocalTransform() {
    var c: Float = 1
    var s: Float = 0

    if angle != 0 {
      let radians = angle.degreesToRadians()
      s = sinf(radians)
      c = cosf(radians)
    }

//    localTransform = float4x4(rows: [
//      [ c * scale.x, s * scale.x, 0, 0],
//      [-s * scale.y, c * scale.y, 0, 0],
//      [           0,           0, 1, 0],
//      [  position.x,  position.y, 0, 1]])

    localTransform = GLKMatrix4Make(
       c * scale.x, s * scale.x, 0, 0,
      -s * scale.y, c * scale.y, 0, 0,
                 0,           0, 1, 0,
        position.x,  position.y, 0, 1)
  }

  private func updateTransform() {
    if localTransformDirty {
      calculateLocalTransform()
      localTransformDirty = false
    }

    if let parent = parent {
//      transform = parent.transform * localTransform
      transform = GLKMatrix4Multiply(parent.transform, localTransform)
    } else {
      transform = localTransform
    }
  }

  /* Used internally to walk the scene graph. */
  public func visit(parentIsDirty: Bool) {
    let dirty = parentIsDirty || localTransformDirty
    if dirty {
      updateTransform()
      visual?.needsRedraw = true
    }

    for child in children {
      child.visit(dirty)
    }

    ppNodeCount += 1  // for debug layer
  }
}

extension Node: CustomStringConvertible {
  public var description: String {
    return String(format: "node %@", name)
  }
}

extension Node {
  /**
   * Orients the node in the direction that it is moving by tweening its rotation
   * angle. This assumes that at 0 degrees the node is facing up.
   *
   * @param rate How fast the node rotates. Must have a value between 0.0 and 1.0,
   *        where smaller means slower; 1.0 is instantaneous.
   */
  public func rotateToVelocity(velocity: GLKVector2, rate: Float) {
    // Determine what the rotation angle of the node ought to be based on the
    // current velocity of its physics body. This assumes that at 0 degrees the
    // node is pointed up, not to the right, so to compensate we add 90 degrees
    // from the calculated angle.
    let newAngle = GLKMathRadiansToDegrees(atan2(velocity.y, velocity.x)) + 90

    // This always makes the node rotate over the shortest possible distance.
    // Because the range of atan2() is -180 to 180 degrees, a rotation from,
    // -170 to -190 would otherwise be from -170 to 170, which makes the node
    // rotate the wrong way (and the long way) around. We adjust the angle to
    // go from 190 to 170 instead, which is equivalent to -170 to -190.
    if newAngle - angle > 180 {
      angle += 360
    } else if angle - newAngle > 180 {
      angle -= 360
    }

    // Use the "standard exponential slide" to slowly tween to the new angle.
    // The greater the value of rate, the faster this goes.
    angle += (newAngle - angle) * rate
  }
}
