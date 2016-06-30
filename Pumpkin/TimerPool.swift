/*!
  Timers allow you to do two things:

  1. Perform an action after a delay.
  2. Perform an action every so often (repeating timer).
  
  Timers run in "game time", i.e. they only advance when the game advances,
  with the same delta time.
*/
public class Timer {
  internal(set) public var duration: Float = 0
  internal(set) public var elapsed: Float = 0

  /*! -1 = indefinitely, 0 = never */
  internal(set) public var repeatCount: Int = 0

  /*! How often repeated already. */
  internal(set) public var repetition: Int = 0

  internal(set) public var block: TimerBlock?

  internal init() { }

  internal func prepareForReuse() {
    elapsed = 0
    repeatCount = 0
    repetition = 0
    block = nil
  }
}

public typealias TimerBlock = (Void) -> Void

/*!
  Manages the timers. Timers allow you to do two things:

  1. Perform an action after a delay.
  2. Perform an action every so often (repeating timer).
*/
public class TimerPool {
  private var activeTimers: [Timer] = []
  private var recycledTimers: [Timer] = []

  public init() { }

  /*!
    Performs a block after a delay. Returns a Timer object that allows you to
    cancel the timer.
  */
  public func afterDelay(delay: Float, perform block: TimerBlock) -> Timer {
    let timer = newTimer()
    timer.duration = delay
    timer.block = block
    activateTimer(timer)
    return timer
  }

  private func newTimer() -> Timer {
    if recycledTimers.count > 0 {
      return recycledTimers.removeLast()
    } else {
      return Timer()
    }
  }

  private func recycleTimer(timer: Timer) {
    timer.prepareForReuse()
    recycledTimers.append(timer)
  }

  private func activateTimer(timer: Timer) {
    assert(activeTimers.find(timer) == nil, "Array already contains object")
    activeTimers.append(timer)
  }

  /*! Cancels a timer prematurely so that it does not perform its action. */
  public func cancelTimer(timer: Timer) {
    if let index = activeTimers.find(timer) {
      recycleTimer(timer)
      activeTimers.removeAtIndex(index)
    }
  }

  /*! Removes all active timers. Does not perform their actions. */
  public func cancelAllTimers() {
    for timer in activeTimers {
      recycleTimer(timer)
    }
    activeTimers.removeAll()
  }

  /*! Updates the timers. You're supposed to call this somewhere from within 
      your game loop. */
  public func updateTimers(dt: Float) {
    var t = 0
    while t < activeTimers.count {
      let timer = activeTimers[t]
      if timer.elapsed >= timer.duration {
        timer.block?()
        timer.repetition += 1
        if timer.repeatCount == 0 || timer.repetition == timer.repeatCount {
          recycleTimer(timer)
          activeTimers.removeAtIndex(t)
        } else {
          timer.elapsed = 0
        }
      } else {
        timer.elapsed += dt
        t += 1
      }
    }
  }

  /*! Empties the pool of recycled timers. */
  public func flushRecycledTimers() {
    recycledTimers.removeAll()
  }
}
