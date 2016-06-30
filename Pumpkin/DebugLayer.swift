import Darwin

public struct Debug {
  public var debugEnabled = false
  public var drawCalls = 0
  public var triangleCount = 0
  public var nodeCount = 0
  public var dirtyCount = 0
  public var fps: Double = 0
}

public var debug = Debug()

/*! Overlay that shows FPS, number of draw calls, etc. */
public class DebugLayer {
  private var previousTime: UInt64
  private var fps: Double = 0

  public init() {
    previousTime = mach_absolute_time()
  }

  public func update() {
    debug.drawCalls = 0
    debug.triangleCount = 0
    debug.nodeCount = 0
    debug.dirtyCount = 0
    debug.fps = measureFrameRate()
  }

  public func render() {
    // TODO: draw this on top of everything else
    if debug.debugEnabled {
      print(String(format: "Draw calls: %d, triangles: %d, nodes: %d (%d), %0.1f FPS", debug.drawCalls, debug.triangleCount, debug.nodeCount, debug.dirtyCount, debug.fps))
    }
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
    return fps
  }
}
