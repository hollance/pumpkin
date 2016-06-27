import Darwin

public var ppDrawCalls = 0
public var ppTriangleCount = 0
public var ppNodeCount = 0
public var ppDirtyCount = 0
public var ppFPS: Double = 0

/*
 * Overlay that shows FPS, number of draw calls, etc.
 */
public class DebugLayer {
  private var previousTime: UInt64
  private var fps: Double = 0

  public init() {
    previousTime = mach_absolute_time()
  }

  public func update() {
    ppDrawCalls = 0
    ppTriangleCount = 0
    ppNodeCount = 0
    ppDirtyCount = 0
    ppFPS = measureFrameRate()
  }

  public func render() {
    // TODO: draw this on top of everything else
    print(String(format: "Draw calls: %d, triangles: %d, nodes: %d (%d), %0.1f FPS", ppDrawCalls, ppTriangleCount, ppNodeCount, ppDirtyCount, ppFPS))
  }

  private func measureFrameRate() -> Double {
    let current = mach_absolute_time()
    var duration = current - previousTime
    previousTime = current
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    duration *= UInt64(info.numer)
    duration /= UInt64(info.denom)

    let alpha = 0.1
    let newfps = 1000000000.0 / Double(duration)
    fps = newfps * alpha + fps * (1.0 - alpha)

    return fps;
  }
}
