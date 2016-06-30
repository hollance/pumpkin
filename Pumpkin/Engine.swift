import QuartzCore
import UIKit

public protocol EngineDelegate: class {
  func update(dt: Float)
}

/*!
 * The main class. It owns everything else.
 */
public class Engine {
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

  public var renderingEngine: RenderingEngine!

  private var displayLink: CADisplayLink!
  private var timestamp: CFTimeInterval = 0

  /*! The current time in the game world. Only advances when the game is
      not paused. You should use this instead of doing your own time with
      CACurrentMediaTime(). */
  private(set) public var time: Float = 0

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

  private dynamic func shouldRedraw(displayLink: CADisplayLink) {
    let now = displayLink.timestamp
    let elapsedSeconds = Float(now - timestamp)
    timestamp = now

    debugLayer.update()

    if elapsedSeconds > 0 {
      time += elapsedSeconds
      delegate?.update(elapsedSeconds)
      renderingEngine.update(elapsedSeconds)
    }

    rootNode.visit(false)
    renderingEngine.render()

    debugLayer.render()
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
