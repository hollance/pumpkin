# Notes

## Drawing order

Currently drawing order rules are very simple: each PPSprite has a drawOrder property. The lower this number, the earlier the sprite is drawn. To put a sprite on top of the other sprites, you have to give it a higher drawOrder. This approach does not take into account the parent-child relationships of the nodes.

This is implemented by sorting the PPSpriteBatch's array of sprites. You have to do this manually whenever you change one or more drawOrder properties. That's a small price to pay and it keeps things simple.

(In addition, the order of the visuals in the render queue also determines the drawing order. Think of these as different layers of content that are independent from each other.)

Other approaches are possible. Here is how Sprite Kit works:

1. Each node has a global z position. Child z values are relative to their parent's, so if the parent has z 100 and the child has z = -1, then the child's absolute z is 99 and it draws before the parent. So while Sprite Kit traverses the scene graph, it calculates the global z value for each node by adding the z's of all its parents.
2. Nodes are drawn in order from smallest z value to largest z value. This is independent of whether a node is a parent or a child. It only looks at the global z value of the node.
3. If two nodes share the same z value, the parents draw before their children, and children are rendered in the order in which they appear in the child array. You can turn off this third step using the ignoresSiblingOrder property, which improves rendering performance.

I think Sprite Kit sets the OpenGL z-position of the vertex, making it really fast. There is no need to sort anything because OpenGL already does this for you. However, using just the vertex-z there is ambiguity in the order in which multiple items with the same z-value are drawn. So to prevent that, you can set ignoresSiblingOrder to NO, and then there is an additional sorting step.

To use the OpenGL vertex z-position you need to use the depth buffer. The vertex position then becomes a GLKVertex3 instead of Vertex2. I had some problems getting this to work properly, though. I didn't quite understand how to set up the ortho projection so that these z values did not get clipped. In addition, some of the sprites didn't properly draw their transparent parts anymore.

(Of course, the advantage of using OpenGL vertex-z is that it goes across layers. So you can have an object from a background layer draw in front of some of your atlas sprites and behind others.)

Here's [how it works in Cocos2D](http://www.learn-cocos2d.com/files/cocos2d-essential-reference-sample/Influencing_the_Draw_Order.html).
