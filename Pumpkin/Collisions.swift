import simd

/*! Checks whether a point lies inside a rectangle. */
public func pointInBox(point: float2, _ box: float4) -> Bool {
	if point.x < box.x { return false }
	if point.y < box.y { return false }
	if point.x > box.z { return false }
	if point.y > box.w { return false }
	return true
}

/*! Checks whether the point is inside the box and if so, calculates what the
    new position and velocity of the collision response should be. */
public func pointBoxCollision(box box: float4, inout position: float2, inout velocity: float2, dt: Float) -> Bool {

	// Note: the collision response is very basic. It essentially moves the
	// position's X or Y-coordinate back to what it was before the collision.
	// This is good enough for most cases. However, a more correct approach
	// would measure how much velocity was needed to reach the box and use
	// only the remainder of the velocity to calculate the response.

	if pointInBox(position, box) {
		let oldX = position.x - velocity.x*dt
		if oldX < box.x || oldX > box.z {
      velocity.x = -velocity.x
      position.x += velocity.x*dt
//TODO cleanup
//			velocity = float2(-velocity.x, velocity.y)
//			position = float2(position.x + velocity.x*dt, position.y)
		} else {
      velocity.y = -velocity.y
      position.y += velocity.y*dt
//			velocity = float2(velocity.x, -velocity.y)
//			position = float2(position.x , position.y + velocity.y*dt)
		}
		return true
	}
	return false
}
