/*
  Based on Robert Penner's easing equations http://robertpenner.com/easing/
  and https://github.com/warrenm/AHEasing

  Note: You can describe the "ease out" function in terms of ease in:

      EaseOut = 1 - EaseIn(1 - t)

  Similarly, you can describe "ease in" in terms of ease out:

      EaseIn = 1 - EaseOut(1 - t)

  You can describe the "ease in-out" function in terms of the two others:

      if t < 0.5
        return 0.5 * EaseIn(t * 2)
      else
        return 0.5 * EaseOut((t - 0.5) * 2) + 0.5

  Or just in terms of ease in:

      if t < 0.5
        return 0.5 * EaseIn(t * 2)
      else
        return 1 - 0.5 * EaseIn(2 - t * 2)

  Or just in terms of ease out:

      if t < 0.5
        return 0.5 * (1 - EaseOut(1 - t * 2))
      else
        return 0.5f * (1 + EaseOut(t * 2 - 1))
 */

import Foundation
import GLKit

public typealias TimingFunction = (Float) -> Float

// MARK: - Linear interpolation (no easing)

// The line y = x
public let TimingFunctionLinear: TimingFunction = { t in
  return t
}

// MARK: - Quadratic easing; t^2

// The parabola y = x^2
public let TimingFunctionQuadraticEaseIn: TimingFunction = { t in
  return t * t
}

// The parabola y = 1 - (x - 1)^2
public let TimingFunctionQuadraticEaseOut: TimingFunction = { t in
  return t * (2.0 - t)
}

public let TimingFunctionQuadraticEaseInOut: TimingFunction = { t in
  if t < 0.5 {
    return 2.0 * t * t
  } else {
    let f = t - 1.0
    return 1.0 - 2.0 * f * f
  }
}

// MARK: - Cubic easing; t^3

// The cubic y = x^3
public let TimingFunctionCubicEaseIn: TimingFunction = { t in
  return t * t * t
}

// The cubic y = 1 + (x - 1)^3
public let TimingFunctionCubicEaseOut: TimingFunction = { t in
  let f = t - 1.0
  return 1.0 + f * f * f
}

public let TimingFunctionCubicEaseInOut: TimingFunction = { t in
  if t < 0.5 {
    return 4.0 * t * t * t
  } else {
    let f = t - 1.0
    return 1.0 + 4.0 * f * f * f
  }
}

// MARK: - Quartic easing; t^4

// The quartic x^4
public let TimingFunctionQuarticEaseIn: TimingFunction = { t in
  return t * t * t * t
}

// The quartic y = 1 - (x - 1)^4
public let TimingFunctionQuarticEaseOut: TimingFunction = { t in
  let f = t - 1.0
  return 1.0 - f * f * f * f
}

public let TimingFunctionQuarticEaseInOut: TimingFunction = { t in
  if t < 0.5 {
    return 8.0 * t * t * t * t
  } else {
    let f = t - 1.0
    return 1.0 - 8.0 * f * f * f * f
  }
}

// MARK: - Quintic easing; t^5

// The quintic y = x^5
public let TimingFunctionQuinticEaseIn: TimingFunction = { t in
  return t * t * t * t * t
}

// The quintic y = 1 + (x - 1)^5
public let TimingFunctionQuinticEaseOut: TimingFunction = { t in
  let f = t - 1.0
  return 1.0 + f * f * f * f * f
}

public let TimingFunctionQuinticEaseInOut: TimingFunction = { t in
  if t < 0.5 {
    return 16.0 * t * t * t * t * t
  } else {
    let f = t - 1.0
    return 1.0 + 16.0 * f * f * f * f * f
  }
}

// MARK: - Sine wave easing; sin(t * PI/2)

// Quarter-cycle of sine wave
public let TimingFunctionSineEaseIn: TimingFunction = { t in
  return sin((t - 1.0) * π/2) + 1.0
}

// Quarter-cycle of sine wave (different phase)
public let TimingFunctionSineEaseOut: TimingFunction = { t in
  return sin(t * π/2)
}

// Half sine wave
public let TimingFunctionSineEaseInOut: TimingFunction = { t in
  return 0.5 * (1.0 - cos(t * π))
}

// MARK: - Circular easing; sqrt(1 - t^2)

// Shifted quadrant IV of unit circle
public let TimingFunctionCircularEaseIn: TimingFunction = { t in
  return 1.0 - sqrt(1.0 - t * t)
}

// Shifted quadrant II of unit circle
public let TimingFunctionCircularEaseOut: TimingFunction = { t in
  return sqrt((2.0 - t) * t)
}

public let TimingFunctionCircularEaseInOut: TimingFunction = { t in
  if t < 0.5 {
    return 0.5 * (1.0 - sqrt(1.0 - 4.0 * t * t))
  } else {
    return 0.5 * sqrt(-4.0 * t * t + 8.0 * t - 3.0) + 0.5
  }
}

// MARK: - Exponential easing, base 2

// The exponential function y = 2^(10(x - 1))
public let TimingFunctionExponentialEaseIn: TimingFunction = { t in
  return (t == 0.0) ? t : pow(2.0, 10.0 * (t - 1.0))
}

// The exponential function y = -2^(-10x) + 1
public let TimingFunctionExponentialEaseOut: TimingFunction = { t in
  return (t == 1.0) ? t : 1.0 - pow(2.0, -10.0 * t)
}

public let TimingFunctionExponentialEaseInOut: TimingFunction = { t in
  if t == 0.0 || t == 1.0 {
    return t
  } else if t < 0.5 {
    return 0.5 * pow(2.0, 20.0 * t - 10.0)
  } else {
    return 1.0 - 0.5 * pow(2.0, -20.0 * t + 10.0)
  }
}

// MARK: - Exponentially-damped sine wave easing

// Damped sine wave
public let TimingFunctionElasticEaseIn: TimingFunction = { t in
	// Version from AHEasing
  return sin(13.0 * π/2 * t) * pow(2.0, 10.0 * (t - 1.0))

	/*
	// Version from Penner
	let period: Float = 0.3
	return sin(((t - 1) - period/4) * twoπ / period) * -pow(2, 10 * (t - 1))
	*/
}

// Damped sine wave
public let TimingFunctionElasticEaseOut: TimingFunction = { t in
	// Version from AHEasing
  return sin(-13.0 * π/2 * (t + 1.0)) * pow(2.0, -10.0 * t) + 1.0

	/*
	// Version from Penner
	let period: Float = 0.3
	return sin((t - period/4) * twoπ / period) * pow(2, -10 * t) + 1
	*/
}

public let TimingFunctionElasticEaseInOut: TimingFunction = { t in
	// Version from AHEasing
  if t < 0.5 {
    return 0.5 * sin(13.0 * π * t) * pow(2.0, 20.0 * t - 10.0)
  } else {
    return 0.5 * sin(-13.0 * π * t) * pow(2.0, -20.0 * t + 10.0) + 1.0
  }

	/*
	// Version from Penner
	let period: Float = 0.3
	if t < 0.5 {
		return 0.5 * sin((2*t - 1 - period/4) * twoπ / period) * -pow(2, 20 * t - 10)
	} else {
		return 0.5 * sin((2*t - 1 - period/4) * twoπ / period) * pow(2, -20 * t + 10) + 1
  }
	*/
}

// MARK: - Overshooting easing (Penner version)

public let TimingFunctionBackEaseIn: TimingFunction = { t in
	// s controls the amount of overshoot. The default value of 1.70158
	// produces an overshoot of 10 percent; s == 0 produces cubic easing
	// with no overshoot.
  let s: Float = 1.70158
  return ((s + 1.0) * t - s) * t * t
}

public let TimingFunctionBackEaseOut: TimingFunction = { t in
  let s: Float = 1.70158
  let f = 1.0 - t
  return 1.0 - ((s + 1.0) * f - s) * f * f
}

public let TimingFunctionBackEaseInOut: TimingFunction = { t in
  let s: Float = 1.70158
  if t < 0.5 {
    let f = 2.0 * t
    return 0.5 * ((s + 1.0) * f - s) * f * f
  } else {
    let f = 2.0 * (1.0 - t)
    return 1.0 - 0.5 * ((s + 1.0) * f - s) * f * f
  }
}

// MARK: - Overshooting easing (AHEasing version)

public let TimingFunctionExtremeBackEaseIn: TimingFunction = { t in
  return (t * t - sin(t * π)) * t
}

public let TimingFunctionExtremeBackEaseOut: TimingFunction = { t in
  let f = 1.0 - t
  return 1.0 - (f * f - sin(f * π)) * f
}

public let TimingFunctionExtremeBackEaseInOut: TimingFunction = { t in
  if t < 0.5 {
    let f = 2.0 * t
    return 0.5 * (f * f - sin(f * π)) * f
  } else {
    let f = 2.0 * (1.0 - t)
    return 1.0 - 0.5 * (f * f - sin(f * π)) * f
  }
}

// MARK: - Exponentially-decaying bounce easing

public let TimingFunctionBounceEaseIn: TimingFunction = { t in
  return 1.0 - TimingFunctionBounceEaseOut(1.0 - t)
}

public let TimingFunctionBounceEaseOut: TimingFunction = { t in
	// Version from Penner
  if t < 1.0 / 2.75 {
    return 7.5625 * t * t
  } else if t < 2.0 / 2.75 {
    let f = t - 1.5 / 2.75
    return 7.5625 * f * f + 0.75
  } else if t < 2.5 / 2.75 {
    let f = t - 2.25 / 2.75
    return 7.5625 * f * f + 0.9375
  } else {
    let f = t - 2.625 / 2.75
    return 7.5625 * f * f + 0.984375
  }

	/*
	// Version from AHEasing
	if t < 4.0/11.0 {
		return 121 * t * t / 16
	} else if t < 8.0/11.0 {
		return 363.0/40.0 * t * t - 99.0/10.0 * t + 17.0/5.0
	} else if t < 9.0/10.0 {
		return 4356.0/361.0 * t * t - 35442.0/1805.0 * t + 16061.0/1805.0
	} else {
		return 54.0/5.0 * t * t - 513.0/25.0 * t + 268.0/25.0
  }
	*/
}

public let TimingFunctionBounceEaseInOut: TimingFunction = { t in
  if t < 0.5 {
    return 0.5 * TimingFunctionBounceEaseIn(t * 2.0)
  } else {
    return 0.5 * TimingFunctionBounceEaseOut(t * 2.0 - 1.0) + 0.5
  }
}

// MARK: - Smoothstep, very similar to sine ease in-out

public let TimingFunctionSmoothstep: TimingFunction = { t in
  return t * t * (3 - 2 * t)
}

// MARK: - Does not interpolate, only shows starting value

public let TimingFunctionStepped: TimingFunction = { t in
  return (t < 1) ? 0 : 1
}

// MARK: - Generating functions

// Creates a shake function with the specified number of oscillations

public func CreateShakeFunction(oscillations: Int) -> TimingFunction {
  return {t in -pow(2.0, -10.0 * t) * sin(t * π * Float(oscillations) * 2.0) + 1.0}
}
