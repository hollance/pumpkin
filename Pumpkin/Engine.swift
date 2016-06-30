import QuartzCore
import UIKit
import simd

public protocol EngineDelegate: class {
  func update(dt: Float)
}

/*!
 * The main class. It owns everything else.
 */
public class Engine {
  /*! Connect this to your main game loop. */
  public weak var delegate: EngineDelegate?

  /*! Whether the engine is currently paused. Default is true. */
  public var isPaused: Bool = true {
    didSet {
      if isPaused {
        print("Pausing game loop")
        displayLink.paused = true
      } else {
        print("Resuming game loop")
        displayLink.paused = false
        timestamp = CACurrentMediaTime()
      }
    }
  }

  /* For returning from the background. */
  private var wasPaused = true

  /*! The root of the scene graph. */
  private(set) public var rootNode = Node()

  /*! The items to be rendered. */
  public var renderQueue = RenderQueue()

  /*! Dimensions of the visible screen. Equal to the bounds of the backing layer. */
  public var viewportSize: float2 {
    return backend?.viewportSize ?? float2.zero
  }

  /*! Fill color for the background. Default is black. */
  public var clearColor = float4(0, 0, 0, 1)

  /*! For special effects. */
  public var modelviewMatrix = float4x4.identity

  /*! The current time in the game world. Only advances when the game is
      not paused. You should use this instead of doing your own time with
      CACurrentMediaTime(). */
  private(set) public var time: Float = 0

  private var backend: RenderBackend!
  private var displayLink: CADisplayLink!
  private var timestamp: CFTimeInterval = 0
  private var debugLayer = DebugLayer()

  public init() {
    setUpDisplayLink()
    registerBackgroundNotifications()
  }

  deinit {
    unregisterBackgroundNotifications()
  }

  /*! Call this to clean up properly! */
  public func tearDown() {
    // Need this method to avoid a retain cycle with CADisplayLink!
    tearDownDisplayLink()
  }

  // MARK: - Display Link

  private func setUpDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(shouldRedraw))
    displayLink.frameInterval = 1
    displayLink.paused = true

    // Note: Adding the display link to NSRunLoopCommonModes instead of
    // NSDefaultRunLoopMode allows the OpenGL view to keep redrawing while
    // the user interacts with a scroll view or other UIKit component.
    displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)

    timestamp = CACurrentMediaTime()
  }

  private func tearDownDisplayLink() {
    displayLink.invalidate()
    displayLink = nil
  }

  // MARK: - Back-end

  public func connectToLayer(layer: CALayer) {
    if let layer = layer as? CAEAGLLayer {
      backend = OpenGLBackend(layer: layer)
    } else {
      fatalError("Unsupported layer type")
    }
  }

  // MARK: - Game Loop

  /*! Updates game time and the scene graph, and renders everything. */
  private dynamic func shouldRedraw(displayLink: CADisplayLink) {
    let now = displayLink.timestamp
    let elapsedSeconds = Float(now - timestamp)
    timestamp = now

    debugLayer.update()

    if elapsedSeconds > 0 {
      time += elapsedSeconds
      delegate?.update(elapsedSeconds)
      backend.update(elapsedSeconds)
      renderQueue.update(elapsedSeconds)
    }

    render()
    debugLayer.render()
  }

  /*! Useful for forcing the current state to (pre)render or render again. */
  public func render() {
    rootNode.visit(false)

    backend.clearColor = clearColor
    backend.modelviewMatrix = modelviewMatrix
    backend.render(renderQueue)
  }

  // MARK: - Background Notifications

  private func registerBackgroundNotifications() {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)

    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplicationWillResignActiveNotification, object: nil)

    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationSignificantTimeChange), name: UIApplicationSignificantTimeChangeNotification, object: nil)
  }

  private func unregisterBackgroundNotifications() {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  private dynamic func applicationDidBecomeActive(notification: NSNotification) {
    if isPaused && !wasPaused {
      isPaused = false
    }
  }

  private dynamic func applicationWillResignActive(notification: NSNotification) {
    wasPaused = isPaused
    isPaused = true
  }

  private dynamic func applicationSignificantTimeChange(notification: NSNotification) {
    timestamp = CACurrentMediaTime()
  }
}
