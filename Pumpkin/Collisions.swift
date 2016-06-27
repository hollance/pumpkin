import GLKit

/*
 * Checks whether a point lies inside a rectangle.
 */
public func PPPointInBox(point: GLKVector2, _ box: GLKVector4) -> Bool {
	if point.x < box.x { return false }
	if point.y < box.y { return false }
	if point.x > box.z { return false }
	if point.y > box.w { return false }
	return true
}

/*
	Additional collision checks (not tested yet):

PP_INLINE BOOL PPBoxIntersectsBox(GLKVector4 box1, GLKVector4 box2)
{
	if (box1.z < box2.x) return NO;
	if (box1.x > box2.z) return NO;
	if (box1.w < box2.y) return NO;
	if (box1.y > box2.w) return NO;
	return YES;
}

PP_INLINE BOOL PPPointInCircle(GLKVector2 point, GLKVector2 center, float radius)
{
	return GLKVector2Length(GLKVector2Subtract(point, center)) < radius;
}

PP_INLINE BOOL PPCircleIntersectsCircle(GLKVector2 center1, float radius1, GLKVector2 center2, float radius2)
{
	return GLKVector2Length(GLKVector2Subtract(center1, center2)) < radius1 + radius2;
}

PP_INLINE BOOL PPCircleIntersectsBox(GLKVector2 center, float radius, GLKVector4 box)
{
	// ???
}
*/

/*
 * Checks whether the point is inside the box and if so, calculates what the
 * new position and velocity of the collision response should be.
 */
public func PPPointBoxCollision(box: GLKVector4, inout position: GLKVector2, inout velocity: GLKVector2, dt: Float) -> Bool {
	//PPAssert(position != nil && velocity != nil, @"Missing output parameter");

	// Note: the collision response is very basic. It essentially moves the
	// position's X or Y-coordinate back to what it was before the collision.
	// This is good enough for most cases. However, a more correct approach
	// would measure how much velocity was needed to reach the box and use
	// only the remainder of the velocity to calculate the response.

	if PPPointInBox(position, box) {
		let oldX = position.x - velocity.x*dt
		if oldX < box.x || oldX > box.z {
			velocity = GLKVector2Make(-velocity.x, velocity.y)
			position = GLKVector2Make(position.x + velocity.x*dt, position.y)
		} else {
			velocity = GLKVector2Make(velocity.x, -velocity.y)
			position = GLKVector2Make(position.x , position.y + velocity.y*dt)
		}
		return true
	}
	return false
}
