import simd

/*! The visual representation of a node. */
public protocol Visual {
  /*! The node that this visual is attached to. */
  weak var node: Node? { get set }

  /*! Used internally: did this visual get changed since last frame? */
  var needsRedraw: Bool { get set }

  /*! Temporarily stops drawing this visual. */
  var hidden: Bool { get set }
}
