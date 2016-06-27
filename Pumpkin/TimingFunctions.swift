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
	static float period = 0.3f;
	return sinf(((t - 1.0f) - period/4.0f) * TWO_PI / period) * -powf(2.0f, 10.0f * (t - 1.0f));
	*/
}

// Damped sine wave
public let TimingFunctionElasticEaseOut: TimingFunction = { t in
	// Version from AHEasing
  return sin(-13.0 * π/2 * (t + 1.0)) * pow(2.0, -10.0 * t) + 1.0

	/*
	// Version from Penner
	static float period = 0.3f;
	return sinf((t - period/4.0f) * TWO_PI / period) * powf(2.0f, -10.0f * t) + 1.0f;
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
	static float period = 0.3f;
	if (t < 0.5f)
		return 0.5f * sinf((2.0f*t - 1.0f - period/4.0f) * TWO_PI / period) * -powf(2.0f, 20.0f * t - 10.0f);
	else
		return 0.5f * sinf((2.0f*t - 1.0f - period/4.0f) * TWO_PI / period) * powf(2.0f, -20.0f * t + 10.0f) + 1.0f;
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
	if (t < 4.0f/11.0f)
		return 121.0f * t * t / 16.0f;
	else if (t < 8.0f/11.0f)
		return 363.0f/40.0f * t * t - 99.0f/10.0f * t + 17.0f/5.0f;
	else if (t < 9.0f/10.0f)
		return 4356.0f/361.0f * t * t - 35442.0f/1805.0f * t + 16061.0f/1805.0f;
	else
		return 54.0f/5.0f * t * t - 513.0f/25.0f * t + 268.0f/25.0f;
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

private func CubicBezier(t: Float, _ c1: Float, _ c2: Float) -> Float {
	//float f = (1.0f - t);
	//return 3.0f * t * f * (c1 * f + c2 * t) + t * t * t;

	let C = 3 * c1
	let B = 3 * (c2 - c1) - C
	let A = 1 - C - B
	return t * (C + t * (B + t * A))
}

/*
 * Returns a timing function modeled as a cubic Bézier curve.
 *
 * The points defining the curve are: (0,0), c1, c2, (1,1).
 *
 * Useful tool for generating the control points: http://netcetera.org/camtf-playground.html
 */
public func PPTimingFunctionWithControlPoints(c1: GLKVector2, _ c2: GLKVector2) -> TimingFunction {
/*
	// Note: None of these approaches work well for control points such as
	// [(2, 1), (-1, 0)] that make the curve loop back on itself.

#if 0

	// Uses a binary search to find a value for t that is close to the real
	// value of t for X. You can tweak the precision and speed with the two
	// constants, MaxIterations and Epsilon.

	const int MaxIterations = 10;
	const float Epsilon = 0.001f;

	return ^(float x)
	{
		int i = 0;
		int p = 1;
		float t = 0.5f;

		while (i < MaxIterations)
		{
			float xFound = CubicBezier(t, c1.x, c2.x);

			if (fabsf(x - xFound) < Epsilon)  // close enough
				break;

			if (xFound < x)
				t += 0.25f/p;
			else
				t -= 0.25f/p;

			i++;
			p <<= 1;
		}

		return CubicBezier(t, c1.y, c2.y);
	};

#elif 0

	// This works but is very inefficient. Every time the block is called it
	// evaluates all the X values for the entire range of "u" (from 0 to 1),
	// in order to find the X value that is closest to the one we're asking for
	// (in "t"), and use that "u" to find the corresponding Y value.

	return ^(float t)
	{
		float smallestU = HUGE_VALF;
		float smallestDiff = HUGE_VALF;

		for (float u = 0.0f; u <= 1.0f; u += 0.01f)
		{
			float x = CubicBezier(u, c1.x, c2.x);
			float diff = fabsf(x - t);
			if (diff < smallestDiff)
			{
				smallestU = u;
				smallestDiff = diff;
			}
			else if (diff > smallestDiff)
			{
				break;  // small optimization
			}
		}

		return CubicBezier(smallestU, c1.y, c2.y);
	};

#elif 0

	// This doesn't work so well. The idea is to create a look-up table where
	// each index is an X-position and each item contains the t-value for that
	// X-position. The problem is that there may be gaps in the table.

	const int TableSize = 1000;
	__block struct { float table[TableSize]; } lut;

	for (float t = 0.0f; t <= 1.0f; t += 0.0001f)
	{
		float x = CubicBezier(t, c1.x, c2.x);
		int i = (int)(x * (TableSize - 1));
		lut.table[i] = t;
	}

	return ^(float x)
	{
		int i = (int)(x * (TableSize - 1));
		float t = lut.table[i];

		return CubicBezier(t, c1.y, c2.y);
	};
	
#elif 1

	// Uses Newton-Raphson
	// Based on code from https://github.com/rdallasgray/bez/blob/master/src/jquery.bez.js
	// and http://st-on-it.blogspot.nl/2011/05/calculating-cubic-bezier-function.html
	// and http://greweb.me/2012/02/bezier-curve-based-easing-functions-from-concept-to-implementation/

	const float C = 3.0f * c1.x;
	const float B = 3.0f * (c2.x - c1.x) - C;
	const float A = 1.0f - C - B;

	float (^derivative)(float t) = ^(float t)
	{
		return C + t * (2.0f * B + 3.0f * A * t);
	};

	return ^(float x)
	{
		float t = x;
		for (int i = 0; i < 10; ++i)
		{
			// This is identical to:
			//     float z = CubicBezier(t, c1.x, c2.x) - x;
			// but faster because we already computed A, B and C for these
			// two control points.
			float z = t * (C + t * (B + t * A)) - x;

			if (fabsf(z) < 1e-3) break;
			t -= z / derivative(t);
		}

		return CubicBezier(t, c1.y, c2.y);
	};

#else
*/

	// Ignores the X component of the curve. This is the fast solution, and you
	// can use it to make the basic animation curves, but it doesn't really use
	// all of the possibilities of a real Bézier curve.

	return { t in return CubicBezier(t, c1.y, c2.y) }

//#endif
}
