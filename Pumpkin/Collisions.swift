import GLKit

/*! Checks whether a point lies inside a rectangle. */
public func pointInBox(point: GLKVector2, _ box: GLKVector4) -> Bool {
	if point.x < box.x { return false }
	if point.y < box.y { return false }
	if point.x > box.z { return false }
	if point.y > box.w { return false }
	return true
}

/*! Checks whether the point is inside the box and if so, calculates what the
    new position and velocity of the collision response should be. */
public func pointBoxCollision(box box: GLKVector4, inout position: GLKVector2, inout velocity: GLKVector2, dt: Float) -> Bool {

	// Note: the collision response is very basic. It essentially moves the
	// position's X or Y-coordinate back to what it was before the collision.
	// This is good enough for most cases. However, a more correct approach
	// would measure how much velocity was needed to reach the box and use
	// only the remainder of the velocity to calculate the response.

	if pointInBox(position, box) {
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
