# Pumpkin Engine

Some of the ideas behind this engine:

- Small and simple. It doesn't have any features I don't need.
- Fast enough for use in real, commercial games.
- Clean architecture.
- Favors composition over inheritance.
- Allows for experimentation.

## Architecture

### Nodes

There is a scene graph, which contains model data, and there are "visuals", which draw (parts of) the scene graph on the screen. The scene graph itself does not draw anything. That is just the model data for the world. 

Note: The scene graph just has model data for what is (going to be) visible. Your game rules may have a different data model. If the game is simple, you can override `PPNode` to have a velocity or other data, or attach such data using the `userData` property, but for a bigger game you might prefer to do that with composition as well (i.e. your game objects have a reference to a node).

The scene graph just consists of nodes. There is no subdivision for scene, layer, sprite, etc.

A node has attributes such as position, scale, rotation angle, drawing order, and a hidden flag. It can have other nodes as children. The node does not have a size, anchor point, or any other drawing properties such as color or texture. A node is just a "pivot" that you can attach other things to.

To actually draw something, you attach a *visual* to the node. There can be many types of visual attachments -- for example, you can also have a visual that does custom OpenGL -- but sprite is the most common.

### Sprites

A sprite is the most basic type of visual attachment for a node. It describes a rectangle with a color and possibly a texture.

There are three types of sprites:

1. A region of a texture from a sprite sheet/texture atlas. This is the most performant and most common way to use sprites.
2. A full texture. Useful for backgrounds and other large images that do not fit in a sprite sheet.
3. A placeholder. When prototyping a game it's handy if you can quickly put a new sprite on the screen without having to re-make the textures or sprite sheets all the time. A placeholder sprite is simply a colored rectangle.

Texture data is stored in `PPTexture` objects.

### Rendering

Visuals can render themselves to the OpenGL canvas. To do this, you add them to the render queue. 

The visual's rendering code does not care about the node hierarchy, just about the (world) position and rotation of the visual's node, the drawing order, and the texture coordinates and color of the sprite.

To draw multiple sprites that share a sprite sheet/texture in one go, add them to a `PPSpriteBatch` object and add that sprite batch to the render queue.

### Anchor point

Nodes do not have an anchor point. The concept of anchor point doesn't make any sense for a node, because a node doesn't have a size. `PPSprite` *does* have an anchor point and by default it is set to the center of the sprite. So if you attach a sprite to a node, the center of the sprite sits at the node's position. To attach it somewhere else, change the anchor point. (Alternatively, you can use a second "pivot" node for this.)

### Drawing order

The engine loops through the visuals in the order that you added them to the queue. You can think of the items in this queue as the layers in your game.

For example, imagine the following situation: 

1. you first draw a background image
2. you need to render a set of sprites in the background
3. some custom OpenGL in between
4. and then another set of sprites on top, using the same texture as the first. 

You need four "layers" for this. Even though the two sprite batches for the sprites can use the same texture, they still need to render using two separate draw calls. It's up to you to manage your visuals properly.

Inside a `PPSpriteBatch`, the drawing order of the sprites is determined by the order the sprites are added (added later is drawn later) and by their `drawOrder` property (higher numbers get drawn on top of lower numbers). If you change the `drawOrder` of one or more sprites, you need to call `sortSpritesByDrawOrder` on the batch object.

## The game loop

Everything in the "visible" world is owned by `PPEngine`. This object owns the scene graph, the render queue, and the game loop.

Again, the Pumpkin scene graph only describes the objects that need to be drawn. For many games you want to have a more extensive data model and only add objects to the scene graph when they become visible.

You provide a delegate for the game loop that gets called every frame. In the delegate callback `update:`, you update the game world (the scene graph) and tell the engine to render.

For ultimate flexibility, you are responsible for telling Pumpkin what should happen. Typically you'll do things in this order:

1. perform your game logic, which modifies the scene graph and possibly the contents of the render queue
2. advance the tweens and timers
3. walk the scene graph to transform local coordinates to global
4. render everything

Note: Nodes do not have their own "update" method.

The `update:` method receives the time that has elapsed since the last update, the *delta time*. You can use this to make the game independent of the frame rate, but for most 2D games using fixed 60 or 30 FPS is easier and looks better ([read more](http://www.learn-cocos2d.com/2013/10/game-engine-multiply-delta-time-or-not/)).

### Timers

You typically need timers to do these two things:

1. Perform an action after a (short) delay.
2. Perform an action every so often.

The `PPTimerPool` object allows you to schedule actions in the future, and cancel them if need be.

## Tweens

You use tweens for special effects to make the game more juicy.

Tweens work on a "target", which can be anything: a node, a sprite, etc. -- any object that conforms to `PPTweenable`. But not all tweens work on every object.

Currently available are:

- `PPMoveFromTween`, `PPMoveToTween`: position (node)
- `PPRotateFromTween`, `PPRotateToTween`: rotation angle (node)
- `PPScaleFromTween`, `PPScaleToTween`: scale (node)
- `PPTintTween`: color (sprite)
- `PPFadeTween`: alpha (sprite)

The move, rotate, and scale tweens come in two variations: the "from" and the "to" tween. From and to refer to the amount and when it is applied; at the start or at the end of the tween, respectively.

The from-tween always starts with the amount of effect applied and then moves the target back to its original state. Think of it as "from the amount back to the original". For example, you just say, "I want to blow up this sprite to 2x its original size and then shrink it back down to what it was." So the target needs to be in its end state already when you apply the tween. This makes sense even for things like level start animations and flying menu items, because you know where you want the objects to end up and then animate towards those positions.

The to-tween is for when you want to keep the node in its current state and over time apply an effect to it, such as scaling it down to make it invisible. Think of it as "from the original state to the amount".

Note: If you set a delay on a tween, it will already assume its initial position (i.e. the state at t = 0) while the delay is in effect. (If it would stay at its current position during the delay, i.e. the end state, then you'd see a jump to the starting value when the delay is over, which is weird. That's why it immediately applies the tweening amount.)

For movement, rotation, and scale tweens, it's OK to have multiple tweens (even of the same type) act on the same node at the same time. For tint and fade tweens this doesn't really make much sense, so it's not supported there.

You don't add the tween to the target but to a `PPTweenPool` object. This object recycles old tweens so that you're not allocating tons of instances all the time.

Note: This is a bit different from the actions system from Sprite Kit and Cocos2D. A tween moves a node between two states over time, but this is added to the current state. It's intended for special effects only, not as a general purpose method to move sprites around.

Call `PPTweenPool` `updateTweens:` to run the tweens at the bottom of the game loop. You need to do this *after* creating any new tweens, or, depending on your timing function, there may be a glitch between when the node is moved to the new state and the animation actually starts.

Typically you'd put a move effect on an object that's otherwise static, a rotation on an object with a fixed orientation, and so on. If you do want to move an object that is already in motion, then don't set its position, scale, or angle property directly (this will overwrite the changes that the tweens are trying to make), but calculate how far the object currently is from its new desired state and "add" the difference.

### Keyframe tweening

Currently, tweens only have one start and end value. There is no `PPKeyframeTween` class that lets you set a a sequence of `PPTween` objects to make an animation with multiple stages.

The best way to approximate keyframe animation is to make all the tweens up-front and set their delays so they happen one after the other. Add them all to the the pool at the same time. This ensures they will all be properly recycled. Give them all the same name so you can remove the entire sequence with a single call.

For the second and next tweens in the sequence, set the `waitUntilAfterDelay` property to YES. This makes sure these tweens do not apply their effect to the target until they actually start.

It's not a good idea to chain tweens together using completion blocks, because if you cancel a tween, the ones that are next will be deallocated and not put back into the pool.

## Collision detection

A bounding box is expressed as "extents". Its type is `GLKVector4`: `x` is the left edge, `y` the top edge, `z` the right edge, and `w` the bottom edge. So it's not like a `CGRect`, which has an origin and a size.

## Touch handling

For now, nodes/sprites do not do their own touch handling (a node cannot do this anyway because it does not have a size).

## 32-bit vs. 64-bit

The engine uses `GLKVector2` for many of its data structures, including `PPTexturedVertex`. This vertex data is sent directly to OpenGL and interpreted as `GL_FLOAT`. This should not cause problems on 64-bit because the `GLKVector2` fields are plain float, not `CGFloat` (which is defined as double on 64-bit). 

That's why the rest of the engine uses float instead of `CGFloat` too (unless the data is natively `CGFloat`, such as in `UIView` properties).

The delta time is a float, not `NSTimeInterval` or `CFTimeInterval` because those are defined as a double. Using a double for calculations with float values will promote those floats to doubles, making them slower on 32-bit.
