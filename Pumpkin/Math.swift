import GLKit

/*! π as a float constant. */
public let π: Float = 3.14159265358979323846

/*! 2π as a float constant. */
public let twoπ: Float = 6.28318530717958647693

/*! π/2 as a float constant. */
public let halfπ: Float = 1.57079632679489661923

public extension Float {
  /*! Converts an angle in degrees to radians. */
  public func degreesToRadians() -> Float {
    return π * self / 180.0
  }

  /*! Converts an angle in radians to degrees. */
  public func radiansToDegrees() -> Float {
    return self * 180.0 / π
  }
}

public let PPVector2Zero = GLKVector2Make(0, 0)

public func PPVector2LengthSquared(vector: GLKVector2) -> Float {
	return vector.v.0 * vector.v.0 + vector.v.1 * vector.v.1
}

/*! Makes sure the length of a vector is not greater than the specified maximum. */
public func PPVector2ClampLength(vector: GLKVector2, max: Float) -> GLKVector2 {
	if GLKVector2Length(vector) > max {
		return GLKVector2MultiplyScalar(GLKVector2Normalize(vector), max)
	} else {
		return vector
  }
}

/*! Ensures that the individual components of the stay within the range
    [min..max], inclusive. */
public func PPVector2Clamp(vector: GLKVector2, min: GLKVector2, max: GLKVector2) -> GLKVector2
{
	return GLKVector2Make(
    fmaxf(fminf(vector.x, max.x), min.x),
    fmaxf(fminf(vector.y, max.y), min.y))
}

/*! Creates and returns a new GLKVector4 using RGB components specified as
    values from 0 to 255. */
public func vectorWithRGB(r: Int, _ g: Int, _ b: Int) -> GLKVector4 {
	return GLKVector4Make(Float(r)/255, Float(g)/255, Float(b)/255, 1)
}

/*! Creates and returns a new GLKVector4 using RGBA components specified as
    values from 0 to 255. */
public func vectorWithRGBA(r: Int, _ g: Int, _ b: Int, _ a: Int) -> GLKVector4 {
	return GLKVector4Make(Float(r)/255, Float(g)/255, Float(b)/255, Float(a)/255)
}

/*! Returns the width in points of a bounding box described by a GLKVector4. */
public func boxWidth(box: GLKVector4) -> Float {
	return box.z - box.x
}

/*! Returns the height in points of a bounding box described by a GLKVector4. */
public func boxHeight(box: GLKVector4) -> Float {
	return box.w - box.y
}

/*! Returns 1.0 if a floating point value is positive; -1.0 if it is negative. */
public func fsignf(value: Float) -> Float {
	return (value >= 0) ? 1 : -1
}

/*! Ensures that a scalar value stays within the range [min..max], inclusive. */
public func fclampf(value: Float, min: Float, max: Float) -> Float {
	return fmaxf(fminf(value, max), min)
}

/*! Performs a linear interpolation between two floats. */
public func flerpf(start start: Float, end: Float, t: Float) -> Float {
	return start + (end - start)*t
}
