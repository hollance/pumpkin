//import simd
import GLKit

/* π as a float constant. */
public let π: Float = 3.14159265358979323846

/* 2π as a float constant. */
public let twoπ: Float = 6.28318530717958647693

/* π/2 as a float constant. */
public let halfπ: Float = 1.57079632679489661923

public extension Float {
  /**
   * Converts an angle in degrees to radians.
   */
  public func degreesToRadians() -> Float {
    return π * self / 180.0
  }

  /**
   * Converts an angle in radians to degrees.
   */
  public func radiansToDegrees() -> Float {
    return self * 180.0 / π
  }
}

public let PPVector2Zero = GLKVector2Make(0, 0)

/*
 * Converts a CGPoint into a GLKVector2 so you can use it with the GLKMath
 * functions from GL Kit.
 */
public func PPVector2WithCGPoint(point: CGPoint) -> GLKVector2 {
	return GLKVector2Make(Float(point.x), Float(point.y))
}

/*
 * Adds (dx, dy) to the vector.
 */
public func PPVector2Offset(vector: GLKVector2, _ dx: Float, _ dy: Float) -> GLKVector2 {
	return GLKVector2Make(vector.x + dx, vector.y + dy)
}

/*
 * Returns a new vector that is 1/vector.
 */
public func PPVector2Reciprocal(vector: GLKVector2) -> GLKVector2 {
	return GLKVector2Make(1/vector.x, 1/vector.y)
}

/*
 * Returns the angle of the vector in radians. The range of the angle is -π
 * to π; an angle of 0 points to the right.
 */
public func PPVector2ToAngle(vector: GLKVector2) -> Float {
	return atan2f(vector.y, vector.x)
}

/*
 * Given an angle in radians, creates a vector of length 1.0 and returns the
 * result as a new vector. An angle of 0 is assumed to point to the right.
 */
public func PPVector2ForAngle(angle: Float) -> GLKVector2 {
	return GLKVector2Make(cosf(angle), sinf(angle))
}

public func PPVector2LengthSquared(vector: GLKVector2) -> Float {
//#if defined(__ARM_NEON__)
//	float32x2_t v = vmul_f32(*(float32x2_t *)&vector,
//							 *(float32x2_t *)&vector);
//	return vpadd_f32(v, v);
	return vector.v.0 * vector.v.0 + vector.v.1 * vector.v.1
}

/*
 * Makes sure the length of a vector is not greater than the specified maximum.
 */
public func PPVector2ClampLength(vector: GLKVector2, _ max: Float) -> GLKVector2 {
	if GLKVector2Length(vector) > max {
		return GLKVector2MultiplyScalar(GLKVector2Normalize(vector), max)
	} else {
		return vector
  }
}

/*
 * Ensures that the individual components of the stay within the range
 * [min..max], inclusive.
 */
//func PPVector2Clamp(vector: float2, _ min: float2, _ max: float2) -> float2
//{
//  var vector = vector
//	vector.x = fmaxf(fminf(vector.x, max.x), min.x)
//	vector.y = fmaxf(fminf(vector.y, max.y), min.y)
//	return vector
//}
public func PPVector2Clamp(vector: GLKVector2, _ min: GLKVector2, _ max: GLKVector2) -> GLKVector2
{
	return GLKVector2Make(
    fmaxf(fminf(vector.x, max.x), min.x),
    fmaxf(fminf(vector.y, max.y), min.y)
    )
}

/*
 * Creates and returns a new GLKVector4 using RGB components specified as
 * values from 0 to 255.
 */
//func PPVector4WithRGB(r: Int, _ g: Int, _ b: Int) -> float4 {
//	return float4(Float(r)/255, Float(g)/255, Float(b)/255, 1)
//}
public func PPVector4WithRGB(r: Int, _ g: Int, _ b: Int) -> GLKVector4 {
	return GLKVector4Make(Float(r)/255, Float(g)/255, Float(b)/255, 1)
}

/*
 * Creates and returns a new GLKVector4 using RGBA components specified as
 * values from 0 to 255.
 */
//func PPVector4WithRGBA(r: Int, _ g: Int, _ b: Int, _ a: Int) -> float4 {
//	return float4(Float(r)/255, Float(g)/255, Float(b)/255, Float(a)/255)
//}
public func PPVector4WithRGBA(r: Int, _ g: Int, _ b: Int, _ a: Int) -> GLKVector4 {
	return GLKVector4Make(Float(r)/255, Float(g)/255, Float(b)/255, Float(a)/255)
}

/*
 * Returns the width in points of a bounding box described by a GLKVector4.
 */
public func PPBoxWidth(box: GLKVector4) -> Float {
	return box.z - box.x
}

/*
 * Returns the height in points of a bounding box described by a GLKVector4.
 */
public func PPBoxHeight(box: GLKVector4) -> Float {
	return box.w - box.y
}

/*
 * Converts a box described by a GLKVector4 into a string.
 */
//func NSString *NSStringFromPPBox(GLKVector4 box)
//{
//	return [NSString stringWithFormat:@"{{%f, %f}, {%f x %f}}", box.x, box.y, PPBoxWidth(box), PPBoxHeight(box)];
//}

/*
 * Returns 1.0 if a floating point value is positive; -1.0 if it is negative.
 */
public func fsignf(value: Float) -> Float {
	return (value >= 0) ? 1 : -1
}

/*
 * Ensures that a scalar value stays within the range [min..max], inclusive.
 */
public func fclampf(value: Float, _ min: Float, _ max: Float) -> Float {
	return fmaxf(fminf(value, max), min);
}

/*
 * Performs a linear interpolation between two floats.
 */
public func flerpf(start: Float, _ end: Float, _ t: Float) -> Float {
	return start + (end - start)*t
}

// TODO: revise these functions -- I'm not sure how many are already built in
