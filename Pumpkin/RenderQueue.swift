/*! 
  Contains a list of renderers. The renderers are asked to render to the
  screen in the order they've been added to the queue.
*/
public class RenderQueue {
  private var queue: [Renderer] = []

  public init() { }

  public func add(renderer: Renderer) {
    insert(renderer, atIndex: queue.count)
  }

  public func insert(renderer: Renderer, atIndex index: Int) {
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
