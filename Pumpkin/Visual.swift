//import simd
import GLKit

/*
 * The visual representation of a node.
 */
public protocol Visual {
  /* The node that this visual is attached to. */
  weak var node: Node? { get set }

  /* Used internally: did this visual get changed since last frame? */
  var needsRedraw: Bool { get set }

  /* Temporarily stops drawing this visual. */
  var hidden: Bool { get set }

//@optional

  /*
   * The point in the visual where it is attached to the node, normalized to the
   * range 0.0f - 1.0f. The default value is (0.5f, 0.5f), i.e. the center of the
   * image.
   */
  var anchorPoint: GLKVector2 { get set }

  /* Whether the visual is displayed horizontally and/or vertically flipped. */
  var flipX: Bool { get set }
  var flipY: Bool { get set }

  var contentSize: GLKVector2 { get }
  var texCoords: GLKVector4 { get }
}

//TODO: split off the optional stuff from Visual into another protocol?
