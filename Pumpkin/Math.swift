import simd

/*! π as a float constant. */
public let π: Float = 3.14159265358979323846

/*! 2π as a float constant. */
public let twoπ: Float = 6.28318530717958647693

/*! π/2 as a float constant. */
public let halfπ: Float = 1.57079632679489661923

public extension Float {
  /*! Converts an angle in degrees to radians. */
  public var degreesToRadians: Float {
    return π * self / 180.0
  }

  /*! Converts an angle in radians to degrees. */
  public var radiansToDegrees: Float {
    return self * 180.0 / π
  }
}

extension float2 {
  public static let zero = float2(0, 0)
}

extension float4 {
  public static let zero = float4(0, 0, 0, 0)
}

extension float4x4 {
  public static let identity = float4x4(1)

  public init(uniformScale s: Float) {
    let X: float4 = [ s, 0, 0, 0 ]
    let Y: float4 = [ 0, s, 0, 0 ]
    let Z: float4 = [ 0, 0, s, 0 ]
    let W: float4 = [ 0, 0, 0, 1 ]
    self = float4x4(rows: [ X, Y, Z, W ])
  }

  public var openGLMatrix: [Float] {
    var m = [Float](count: 16, repeatedValue: 0)
    m[0] = self[0].x
    m[1] = self[0].y
    m[2] = self[0].z
    m[3] = self[0].w
    m[4] = self[1].x
    m[5] = self[1].y
    m[6] = self[1].z
    m[7] = self[1].w
    m[8] = self[2].x
    m[9] = self[2].y
    m[10] = self[2].z
    m[11] = self[2].w
    m[12] = self[3].x
    m[13] = self[3].y
    m[14] = self[3].z
    m[15] = self[3].w
    return m
  }
}

/*
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
*/

/*! Creates and returns a new GLKVector4 using RGB components specified as
    values from 0 to 255. */
public func vectorWithRGB(r: Int, _ g: Int, _ b: Int) -> float4 {
	return float4(Float(r)/255, Float(g)/255, Float(b)/255, 1)
}

/*! Creates and returns a new GLKVector4 using RGBA components specified as
    values from 0 to 255. */
public func vectorWithRGBA(r: Int, _ g: Int, _ b: Int, _ a: Int) -> float4 {
	return float4(Float(r)/255, Float(g)/255, Float(b)/255, Float(a)/255)
}

/*! Returns the width in points of a bounding box described by a GLKVector4. */
public func boxWidth(box: float4) -> Float {
	return box.z - box.x
}

/*! Returns the height in points of a bounding box described by a GLKVector4. */
public func boxHeight(box: float4) -> Float {
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
