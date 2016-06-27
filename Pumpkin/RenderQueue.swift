/*
 * Contains a list of renderers.
 */
public class RenderQueue {
  private var queue: [Renderer] = []

  public init() {
  }

  public func add(renderer: Renderer) {
    insert(renderer, atIndex: queue.count)
  }

  public func insert(renderer: Renderer, atIndex index: Int) {
//    assert(queue.find(renderer) == nil, "Queue already contains renderer")
    queue.insert(renderer, atIndex: index)
  }

  public func remove(renderer: Renderer) {
    var t = 0
    while t < queue.count {
      if queue[t] === renderer {
        queue.removeAtIndex(t)
      } else {
        t += 1
      }
    }
// GRRR this doesn't seem to work
//    if let index = queue.indexOf(renderer) {
//      queue.removeAtIndex(index)
//    }
  }

  public func removeAllRenderers() {
    queue.removeAll()
  }

  public func update(dt: Float) {
    for renderer in queue {
      renderer.update(dt)
    }
  }

  public func render(context: RenderContext) {
    for renderer in queue {
      renderer.render(context)
    }
  }
}
