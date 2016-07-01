import UIKit
import simd
import Pumpkin

class Game: UIViewController, EngineDelegate {
  @IBOutlet weak var openGLView: OpenGLView!

	let engine = Engine()

  var tweenPool = TweenPool()
  var timerPool = TimerPool()
	let spriteBatch = SpriteBatch()
  var spriteSheet: SpriteSheet!
  var worldSize = float2.zero

  var logoTexture: Texture!

  var worldNode: Node!

  var paddleNode: Node!
	var previousTouchLocation = CGPoint.zero
	var paddleScale = float2(1, 1)

	var leftEyeNode: Node!
	var rightEyeNode: Node!
	var mouthNode: Node!
	var nextBlinkTime: Float = 0
	var blinkOn = false
	var happy = false

	var topBorder: Node!
	var leftBorder: Node!
	var rightBorder: Node!

	var balls: [Node] = []
	var bricks: [Node] = []
  var deadBricks: [Node] = []

  var hitBorder = false
  var hitPaddle = false
  var hitBrick = false
	var hitVector = float2.zero

	// Distance to the center of the border that was hit, in a percentage
	// of the border's length (half of the length, actually, so it goes from
	// -100% to +100%). We multiply this by the maximum tumble angle to get
	// the amount of rotation.
	var tumbleDistance: Float = 0

	var colorGlitchCounter = 0

  var music: Music!
  var ballBorderSound: SoundEffect!
  var ballPaddleSound: SoundEffect!
  var ballBrickSound: [SoundEffect] = []
  var brickSoundCount = 0
  var lastBrickSoundTime: Float = 0

  override func viewDidLoad() {
    super.viewDidLoad()

    // A two-finger long press restarts the game.
    let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    longPressGestureRecognizer.numberOfTouchesRequired = 2
    view.addGestureRecognizer(longPressGestureRecognizer)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // If we init the rendering engine in viewDidLoad, then the bounds of the
    // view aren't correct yet. This is a better place.
    if engine.delegate == nil {
      setUp()
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.

    tweenPool.flushRecycledTweens()
    timerPool.flushRecycledTimers()
  }

  override func prefersStatusBarHidden() -> Bool {
    return true
  }

  // MARK: - Initialization

  func setUp() {
    settings.customizeEffects()

    engine.delegate = self
    engine.connectToLayer(openGLView.layer)

    //worldSize = engine.viewportSize

    // Quick-n-dirty support for iPhone. We pretend it's still an iPad but
    // scale down to fit the iPhone's screen dimensions.
    worldSize = float2(1024, 768)
    engine.modelviewMatrix = float4x4([
      [ engine.viewportSize.x / worldSize.x, 0, 0, 0 ],
      [ 0, engine.viewportSize.y / worldSize.y, 0, 0 ],
      [ 0, 0, 1, 0 ],
      [ 0, 0, 0, 1 ],
    ])

    // TODO: choose filename based on device type?
    let filename = "Sprites@2x"
    spriteSheet = SpriteSheet(filename: filename)

    let texture = Texture(filename: filename)
    texture.premultipliedAlpha = false
    spriteBatch.texture = texture

    logoTexture = Texture(filename: "Juicy@2x")

    setUpSound()
    restartGame()

    // Draw the first frame, or the screen will flash briefly at startup.
    engine.render()
  }

  func setUpSound() {
    music = Music(filename: "Pinball Spring.mp3")
    music.volume = 0.5

    ballBorderSound = SoundEffect(filename: "Ball-Border.caf")
    ballPaddleSound = SoundEffect(filename: "Ball-Paddle.caf")

    for t in 0..<12 {
      let filename = String(format: "Ball-Brick-%d.caf", t + 1)
      ballBrickSound.append(SoundEffect(filename: filename))
    }

    brickSoundCount = 0
  }

  func restartGame() {
    engine.renderQueue.removeAllRenderers()
    spriteBatch.removeAllSprites()
    tweenPool.removeAllTweens(finish: false)
    timerPool.cancelAllTimers()
    engine.rootNode.removeAllChildren()

    worldNode = Node()
    engine.rootNode.add(worldNode)

    engine.renderQueue.add(spriteBatch)

    // Position the root node in the center of the screen, so we can rotate
    // the world around that. But we still want the top-left corner of the
    // world in the top-left corner of the screen, so move the world node back.
    engine.rootNode.angle = 0
    engine.rootNode.position = float2(worldSize.x/2, worldSize.y/2)
    worldNode.position = -engine.rootNode.position

    setUpPaddle()
    setUpBorders()
    setUpBricks()
    setUpBalls()
    applySettings()

    spriteBatch.sortSpritesByDrawOrder()

    if settings.tweeningEnabled {
      performTweening()
    }

    engine.isPaused = false
  }

  func setUpPaddle() {
    paddleScale = float2(1, 1)

    let paddleSprite = Sprite()
    paddleSprite.spriteFrame = spriteSheet["Paddle"]
    paddleSprite.drawOrder = 100
    spriteBatch.add(paddleSprite)

    paddleNode = Node()
    paddleNode.position = float2(worldSize.x/2, worldSize.y - 60)
    paddleNode.visual = paddleSprite
    paddleNode.name = "Paddle"
    worldNode.add(paddleNode)
	
    let leftEyeSprite = Sprite()
    leftEyeSprite.spriteFrame = spriteSheet["Eye"]
    leftEyeSprite.drawOrder = paddleSprite.drawOrder + 1
    spriteBatch.add(leftEyeSprite)

    leftEyeNode = Node()
    leftEyeNode.visual = leftEyeSprite
    leftEyeNode.name = "Left Eye"
    paddleNode.add(leftEyeNode)

    let rightEyeSprite = Sprite()
    rightEyeSprite.spriteFrame = spriteSheet["Eye"]
    rightEyeSprite.drawOrder = paddleSprite.drawOrder + 1
    spriteBatch.add(rightEyeSprite)

    rightEyeNode = Node()
    rightEyeNode.visual = rightEyeSprite
    rightEyeNode.name = "Right Eye"
    paddleNode.add(rightEyeNode)

    let mouthSprite = Sprite()
    mouthSprite.spriteFrame = spriteSheet["Mouth"]
    mouthSprite.drawOrder = paddleSprite.drawOrder + 1
    spriteBatch.add(mouthSprite)

    mouthNode = Node()
    mouthNode.visual = mouthSprite
    mouthNode.name = "Mouth"
    paddleNode.add(mouthNode)

    nextBlinkTime = engine.time + 2
    blinkOn = true
  }

  func setUpBorders() {
    let leftBorderShape = Border()
    leftBorderShape.length = worldSize.y
    engine.renderQueue.add(leftBorderShape)

    leftBorder = Node()
    leftBorder.position = float2(0, 0)
    leftBorder.angle = 0
    leftBorder.visual = leftBorderShape
    leftBorder.name = "Left Border"
    worldNode.add(leftBorder)

    let rightBorderShape = Border()
    rightBorderShape.length = worldSize.y
    engine.renderQueue.add(rightBorderShape)

    rightBorder = Node()
    rightBorder.position = float2(worldSize.x, worldSize.y)
    rightBorder.angle = 180
    rightBorder.visual = rightBorderShape
    rightBorder.name = "Right Border"
    worldNode.add(rightBorder)

    let topBorderShape = Border()
    topBorderShape.length = worldSize.x
    engine.renderQueue.add(topBorderShape)

    topBorder = Node()
    topBorder.position = float2(worldSize.x, 0)
    topBorder.angle = 90
    topBorder.visual = topBorderShape
    topBorder.name = "Top Border"
    worldNode.add(topBorder)
  }

  func setUpBricks() {
    bricks = []

    for j in 0..<8 {
      for i in 0..<9 {
        let brickSprite = Sprite()
        brickSprite.spriteFrame = spriteSheet["Brick"]
        spriteBatch.add(brickSprite)
        
        brickSprite.flipX = (i % 3 == 0)
        brickSprite.flipY = (j % 2 == 0)

        /**/
        // For testing Animation's sprite frame-based animation.
        if i == 0 && j == 0 {
          var anim = Animation()
          anim.spriteFrames = [
            spriteSheet["Brick"]!,
            spriteSheet["Paddle"]!,
            spriteSheet["BallRound"]!,
            spriteSheet["BallBowling"]!,
            spriteSheet["BallSquare"]!,
            ]
          anim.timePerFrame = 0.4
          anim.loops = -1 //5
          anim.restoreOriginalFrame = true
          brickSprite.add(anim, withName: "TestAnim")
          brickSprite.playAnimation("TestAnim", fromFrame: 3)
        }
        /**/
        
        let brickNode = Node()
        brickNode.position = float2(152 + Float(i)*90, 90 + Float(j)*40)
        brickNode.visual = brickSprite
        brickNode.name = "Brick"
        worldNode.add(brickNode)

        // For testing bounding box calculation.
        if i == 0 && j == 7 {
          let placeholderSprite = Sprite()
          placeholderSprite.placeholderContentSize = brickSprite.contentSize
          placeholderSprite.color = vectorWithRGB(255, 255, 0)
          engine.renderQueue.insert(placeholderSprite, atIndex: 0)

          let placeholderNode = Node()
          placeholderNode.position = brickNode.position
          placeholderNode.visual = placeholderSprite
          placeholderNode.name = "Placeholder"
          placeholderNode.userData = brickSprite
          worldNode.add(placeholderNode)
        }

        bricks.append(brickNode)
      }
    }

    deadBricks = []
  }

  func setUpBalls() {
    balls = []

    if settings.maxBalls > 1 {
      addExtraBall()
    } else {
      addBall()
    }
  }

  func addExtraBall() {
    addBall()

    if balls.count < settings.maxBalls {
      timerPool.afterDelay(0.5 + Float.random() * 3, perform: addExtraBall)
    }
  }

  func addBall() {
    let spriteName: String
    if settings.ballType == 0 {
      spriteName = "BallRound"
    } else if settings.ballType == 1 {
      spriteName = "BallBowling"
    } else {
      spriteName = "BallSquare"
    }

    let ballSprite = Sprite()
    ballSprite.spriteFrame = spriteSheet[spriteName]
    ballSprite.drawOrder = 200
    spriteBatch.add(ballSprite)

    let ballNode = Ball()
    ballNode.position = float2(worldSize.x / 2, worldSize.y - 220)
    ballNode.visual = ballSprite
    ballNode.name = "Ball"
    worldNode.add(ballNode)

    balls.append(ballNode)

    // Assign a random angle to the ball's velocity
    let ballSpeed: Float = 400
    let angle: Float = (Float.random() * 360).degreesToRadians
    ballNode.velocity = float2(cosf(angle)*ballSpeed, sinf(angle)*ballSpeed)
  }

  // MARK: - Settings

  func applySettings() {
    applyColorSettings()
    applyMusicSettings()
    applyFaceSettings()
  }

  func applyColorSettings() {
    if settings.colorEnabled {
      engine.clearColor = vectorWithRGB(73, 10, 61)

      paddleNode.sprite.color = vectorWithRGB(233, 127, 2)
      
      for ballNode in balls {
        ballNode.sprite.color = vectorWithRGB(248, 202, 0)
      }

      let borderColor = vectorWithRGB(189, 21, 80)
      (topBorder.shape as! Border).color = borderColor
      (leftBorder.shape as! Border).color = borderColor
      (rightBorder.shape as! Border).color = borderColor

      for brickNode in bricks {
        brickNode.sprite.color = borderColor
      }
    }
    else
    {
      engine.clearColor = vectorWithRGB(0, 0, 0)

      let whiteColor = vectorWithRGB(255, 255, 255)

      paddleNode.sprite.color = whiteColor

      for ballNode in balls {
        ballNode.sprite.color = whiteColor
      }

      (topBorder.shape as! Border).color = whiteColor
      (leftBorder.shape as! Border).color = whiteColor
      (rightBorder.shape as! Border).color = whiteColor

      for brickNode in bricks {
        brickNode.sprite.color = whiteColor
      }
    }
  }

  func applyMusicSettings() {
    if settings.musicEnabled {
      music.play()
    } else {
      music.stop()
    }
  }

  func applyFaceSettings() {
    if settings.paddleFace {
      leftEyeNode.sprite.hidden = false
      rightEyeNode.sprite.hidden = false
      mouthNode.sprite.hidden = false
    } else {
      leftEyeNode.sprite.hidden = true
      rightEyeNode.sprite.hidden = true
      mouthNode.sprite.hidden = true
    }

    leftEyeNode.position = float2(-settings.paddleEyeSeparation, -2)
    rightEyeNode.position = float2(settings.paddleEyeSeparation, -2)
    mouthNode.position = float2(0, 3)

    leftEyeNode.scale = float2(settings.paddleEyeScale, settings.paddleEyeScale)
    rightEyeNode.scale = leftEyeNode.scale
    mouthNode.scale = float2(settings.paddleMouthScale, settings.paddleMouthScale)
  }

  // MARK: - Tweening

  func performTweening() {
    var nodes = bricks
    nodes.append(paddleNode)

    for node in nodes {
      var delay = settings.tweeningDelay * Float.random()

      if node === paddleNode {  // I like the look of this better
        delay = 0
      }

      if settings.tweenYPosition {
        let tween = tweenPool.moveFromTween()
        tween.target = node
        tween.amount = float2(0, -worldSize.y*0.8)
        tween.duration = settings.tweeningDuration
        tween.delay = delay
        tween.timingFunction = timingFunction()
        tweenPool.add(tween)
      }

      if settings.tweenRotation {
        let tween = tweenPool.rotateFromTween()
        tween.target = node
        tween.amount = -45 + Float.random() * 90
        tween.duration = settings.tweeningDuration
        tween.delay = delay
        tween.timingFunction = timingFunction()
        tweenPool.add(tween)
      }

      if settings.tweenScale {
        let tween = tweenPool.scaleFromTween()
        tween.target = node
        tween.amount = float2(0.25, 0.25)
        tween.duration = settings.tweeningDuration
        tween.delay = delay
        tween.timingFunction = timingFunction()
        tweenPool.add(tween)
      }

      if settings.tweenAlpha {
        node.sprite.alpha = 0

        let tween = tweenPool.fadeTween()
        tween.target = node.sprite
        tween.startAlpha = 0
        tween.endAlpha = 1
        tween.duration = settings.tweeningDuration
        tween.delay = delay
        tween.timingFunction = timingFunction()
        tweenPool.add(tween)
      }
    }

    if settings.tweenBorders {
      let tweenLeft = tweenPool.moveFromTween()
      tweenLeft.target = leftBorder
      tweenLeft.amount = float2(-50, 0)
      tweenLeft.duration = settings.tweeningDuration
      tweenLeft.delay = 0
      tweenLeft.timingFunction = TimingFunctionBounceEaseOut
      tweenPool.add(tweenLeft)

      let tweenTop = tweenPool.moveFromTween()
      tweenTop.target = topBorder
      tweenTop.amount = float2(0, -50)
      tweenTop.duration = settings.tweeningDuration
      tweenTop.delay = settings.tweeningDuration// 0.5
      tweenTop.timingFunction = TimingFunctionBounceEaseOut
      tweenPool.add(tweenTop)

      let tweenRight = tweenPool.moveFromTween()
      tweenRight.target = rightBorder
      tweenRight.amount = float2(50, 0)
      tweenRight.duration = settings.tweeningDuration
      tweenRight.delay = 0
      tweenRight.timingFunction = TimingFunctionBounceEaseOut
      tweenPool.add(tweenRight)
    }

    if settings.tweenLogo {
      let logoSprite = Sprite()
      logoSprite.texture = logoTexture
      engine.renderQueue.add(logoSprite)

      let logoNode = Node()
      logoNode.visual = logoSprite
      logoNode.position = float2(0, worldSize.y/2 + logoTexture.contentSize.y/2)
      engine.rootNode.add(logoNode)

      let moveTween = tweenPool.moveToTween()
      moveTween.target = logoNode
      moveTween.amount = float2(0, -(worldSize.y + logoTexture.contentSize.y)/2)
      moveTween.duration = 2
      moveTween.delay = 1
      moveTween.timingFunction = TimingFunctionExponentialEaseOut
      tweenPool.add(moveTween)

      let rotateTween = tweenPool.rotateToTween()
      rotateTween.target = logoNode
      rotateTween.amount = 360
      rotateTween.duration = moveTween.duration
      rotateTween.delay = moveTween.delay + moveTween.duration - 0.25
      rotateTween.timingFunction = moveTween.timingFunction
      tweenPool.add(rotateTween)

      let scaleTween = tweenPool.scaleToTween()
      scaleTween.target = logoNode
      scaleTween.amount = float2(4, 4)
      scaleTween.duration = moveTween.duration
      scaleTween.delay = rotateTween.delay
      scaleTween.timingFunction = moveTween.timingFunction
      tweenPool.add(scaleTween)

      let fadeTween = tweenPool.fadeTween()
      fadeTween.target = logoNode.sprite
      fadeTween.startAlpha = 1
      fadeTween.endAlpha = 0
      fadeTween.duration = moveTween.duration
      fadeTween.delay = rotateTween.delay
      fadeTween.timingFunction = moveTween.timingFunction
      tweenPool.add(fadeTween)

      timerPool.afterDelay(4) {
        self.engine.renderQueue.remove(logoNode.sprite)
        logoNode.removeFromParent()
      }
    }
  }

  func timingFunction() -> TimingFunction {
    switch settings.easingEquation {
      case 1: return TimingFunctionQuadraticEaseOut
      case 2: return TimingFunctionBackEaseOut
      case 3: return TimingFunctionBounceEaseOut
      default: return TimingFunctionLinear
    }
  }

  // MARK: - Actions

  private dynamic func longPress(sender: UILongPressGestureRecognizer) {
    if sender.state == .Ended {
      restartGame()
    }
  }

  // MARK: - Touch handling

  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let touch = touches.first {
      previousTouchLocation = touch.locationInView(view)
    }
  }

  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let touch = touches.first {
      let newLocation = touch.locationInView(view)
      let deltaX = Float(newLocation.x - previousTouchLocation.x)
      previousTouchLocation = newLocation

      let newX = fclampf(paddleNode.position.x + deltaX, min: Border.thickness + 65, max: worldSize.x - Border.thickness - 65)
      paddleNode.position = float2(newX, paddleNode.position.y)

      if settings.paddleStretch {
        var newScale = float2(1 + fabsf(deltaX)/50, 1 - fabsf(deltaX)/200)
        
        // Make sure the new scale doesn't become too small. If allowed to
        // become 0, the paddle will disappear, never to return.
        newScale = clamp(newScale, min: float2(0.5, 0.4), max: float2(10.0, 10.0))

        scalePaddle(newScale)
      }
    }
  }

  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    // Note: When the touch goes out the screen or is cancelled, reset the
    // paddle scale or it will look funky.
    scalePaddle(float2(1, 1))
  }

  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    scalePaddle(float2(1, 1))
  }

  func scalePaddle(newScale: float2) {
    // We cannot set the new scale directly on the paddle because there may
    // be tweens active that also change the scale (the jelly effect). Instead,
    // figure out by how much the scale should change and "add" that to the
    // existing scale.

    let diff = newScale / paddleScale
    paddleScale = newScale
    paddleNode.scale *= diff
  }

  // MARK: - Game loop

  func update(dt: Float) {
    // Make time go faster or slower. If dt is too small then skip this frame,
    // or risk dividing by 0!
    var dt = dt
    dt *= settings.timeScale
    if dt < FLT_EPSILON { return }

    hitBorder = false
    hitPaddle = false
    hitBrick = false
    tumbleDistance = 0

    for ballNode in balls {
      updateBall(ballNode as! Ball, deltaTime: dt)
    }

    if hitBorder || hitPaddle || hitBrick {

      if settings.brickJelly {
        // If the cumulative hits option is disabled, we need to stop any
        // existing jelly effects on the paddle. However, because such an
        // animation may still be under way, it needs to jump to its end
        // state so the original paddle scale is restored. (Unlike for the
        // bricks, we cannot just set the paddle scale to 1.0 because other
        // things influence that scale factor as well.)
        if !settings.cumulativeHits {
          tweenPool.remove(forTarget: paddleNode, withName: "brickJelly", finish: true)
        }

        let tween = tweenPool.scaleFromTween()
        tween.target = paddleNode
        tween.amount = float2(1.3, 1.2)
        tween.duration = 0.5
        tween.timingFunction = TimingFunctionBounceEaseOut
        tween.name = "brickJelly"
        tweenPool.add(tween)

        for brickNode in bricks {
          // By always setting the scale property back to 1.0 and calling
          // replaceAnimation to stop any previous tweens, hits on bricks
          // do not accumulate. (That would look weird because the bricks
          // are so close together.)
          //
          // Note: this approach does create a small problem when the
          // ball hits something while the bricks are still appearing at
          // the start of the level, because it overwrites that other
          // scaling tween. (I won't fix that for this demo.)

          brickNode.scale = float2(1, 1)

          let tween = tweenPool.scaleFromTween()
          tween.target = brickNode
          tween.amount = float2(1.15, 1.15)
          tween.duration = 0.5
          tween.timingFunction = TimingFunctionBounceEaseOut
          tween.name = "brickJelly"
          tweenPool.replace(tween, finish: false)
        }
      }

      if settings.screenShakeEnabled {
        tweenPool.screenShake(node: worldNode,
          amount: hitVector * settings.screenShakePower,
          oscillations: 10,
          duration: settings.screenShakeDuration)
      
        tweenPool.screenShake(node: paddleNode,
          amount: float2(0, hitVector.y * settings.screenShakePower * -1.5),
          oscillations: 10,
          duration: settings.screenShakeDuration)
      }

      if settings.screenTumbleEnabled {
        let angle = (settings.screenShakePower * 4).degreesToRadians * tumbleDistance
        tweenPool.screenTumble(node: engine.rootNode, angle: angle, oscillations: 10, duration: settings.screenShakeDuration)
      }

      if settings.screenZoomEnabled {
        tweenPool.screenZoom(node: engine.rootNode,
          amount: float2(1.05, 1.05),
          oscillations: 10,
          duration: settings.screenShakeDuration)
      }
    }

    if hitBrick && settings.colorGlitchEnabled {
      colorGlitchCounter = 1
    }

    updateColorGlitch()

    if settings.paddleFace {
      updatePaddle(dt)
    }

    updateDeadBricks(dt)

    tweenPool.updateTweens(dt)
    timerPool.updateTimers(dt)

    // For testing boundingBox calculations.
    if let placeholderNode = worldNode.childNode(withName: "Placeholder") {
      if let brickSprite = placeholderNode.userData as? Sprite {
        placeholderNode.position = brickSprite.node!.position
        placeholderNode.sprite.hidden = brickSprite.hidden
        let boundingBox = brickSprite.boundingBox
        placeholderNode.sprite.placeholderContentSize = float2(boxWidth(boundingBox), boxHeight(boundingBox))
      }
    }
  }

  func updatePaddle(dt: Float) {
    let firstBall = balls[0]
    let deltaX = paddleNode.position.x - firstBall.position.x
    let deltaY = paddleNode.position.y - firstBall.position.y

    // Open mouth

    var mouthScaleY: Float = 1
    let halfHeight = worldSize.y / 2
    if deltaY < halfHeight {
      if !happy { mouthScaleY = 0.2 * settings.paddleMouthScale }
      mouthNode.angle = 0
    } else {
      happy = false
      mouthScaleY *= (deltaY - halfHeight) / halfHeight
      mouthNode.angle = 180
    }

    mouthNode.scale = float2(mouthNode.scale.x, mouthScaleY)
    mouthNode.sprite.hidden = (settings.paddleMouthScale == 0)

    // Look at the ball

    if settings.paddleLookAtBall {
      // Cross-eyed
      //var deltaX = firstBall.position.x - leftEyeNode.position.x
      //var deltaY = firstBall.position.y - leftEyeNode.position.y
      leftEyeNode.angle = (atan2f(deltaY, deltaX)).radiansToDegrees - 90

      // Cross-eyed
      //deltaX = firstBall.position.x - rightEyeNode.position.x
      //deltaY = firstBall.position.y - rightEyeNode.position.y
      rightEyeNode.angle = (atan2f(deltaY, deltaX)).radiansToDegrees - 90
    } else {
      leftEyeNode.angle = 0
      rightEyeNode.angle = 0
    }

    // Blinking

    if engine.time >= nextBlinkTime {
      blinkOn = !blinkOn
      nextBlinkTime = engine.time + (blinkOn ? 1 + Float.random() * 2 : 0.1)
    }

    leftEyeNode.sprite.hidden = !blinkOn
    rightEyeNode.sprite.hidden = !blinkOn
  }

  func updateBall(ballNode: Ball, deltaTime dt: Float) {
    // Calculate new position of the ball
    
    let velocityStep = ballNode.velocity * dt
    var newPosition = ballNode.position + velocityStep
    
    // Check for collision with screen borders

    var newVelocity = ballNode.velocity
    var hitBorder = false

    if newPosition.x <= Border.thickness {
      newVelocity.x = -newVelocity.x
      newPosition.x = Border.thickness
      hitBorder = true
      tumbleDistance = 2 * (ballNode.position.y - worldSize.y/2) / worldSize.y

      if settings.bouncyLinesEnabled, let border = leftBorder.shape as? Border {
        border.animateHit(atSpot: ballNode.position.y)
      }
    }
    else if newPosition.x >= worldSize.x - Border.thickness {
      newVelocity.x = -newVelocity.x
      newPosition.x = worldSize.x - Border.thickness
      hitBorder = true
      tumbleDistance = -2 * (ballNode.position.y - worldSize.y/2) / worldSize.y

      if settings.bouncyLinesEnabled, let border = rightBorder.shape as? Border {
        border.animateHit(atSpot: worldSize.y - ballNode.position.y)
      }
    }

    if newPosition.y <= Border.thickness {
      newVelocity.y = -newVelocity.y
      newPosition.y = Border.thickness
      hitBorder = true
      tumbleDistance = -2 * (ballNode.position.x - worldSize.x/2) / worldSize.x

      if settings.bouncyLinesEnabled, let border = topBorder.shape as? Border {
        border.animateHit(atSpot: worldSize.x - ballNode.position.x)
      }
    }
    else if newPosition.y >= worldSize.y {
      // Note: in a real game this would be the game over condition.

      newVelocity.y = -newVelocity.y
      newPosition.y = worldSize.y
      hitBorder = true
      tumbleDistance = 2 * (ballNode.position.x - worldSize.x/2) / worldSize.x
    }

    if hitBorder {
      self.hitBorder = true
    }

    if hitBorder && settings.soundBorder {
      ballBorderSound.play()
    }

    // Check for collision with the paddle

    var hitPaddle = false
    if pointBoxCollision(box: paddleNode.sprite.boundingBox, position: &newPosition, velocity: &newVelocity, dt: dt)  {
      hitPaddle = true

      if settings.soundPaddle {
        ballPaddleSound.play()
      }

      /*
      // If gravity is enabled, then give the ball a bit extra push
      // so you can overcome the effects of gravity.
      if ([_settings floatValueForKey:@"gravity"] > 0.0f)
      {
        newVelocity.y -= 100.0f * [_settings floatValueForKey:@"gravity"];
        newVelocity.y = fminf(newVelocityY, 400.0f);
      }
      */

      happy = true

      // Note: In the Cocos2D version, I do this with a CCScaleTo action
      // with ease out, which looks nicer. But here I want to play with
      // timers.

      timerPool.afterDelay(1) { self.happy = false }
    }

    if hitPaddle {
      self.hitPaddle = true
    }

    // Check for collision with bricks

    var hitBrick = false
    var brickToDestroy: Node?

    for brickNode in bricks {
      if pointBoxCollision(box: brickNode.sprite.boundingBox, position: &newPosition, velocity: &newVelocity, dt: dt) {
        hitBrick = true

        if settings.soundBrick {
          if engine.time - lastBrickSoundTime > 1 {
            brickSoundCount = 0
          }

          ballBrickSound[brickSoundCount].play()

          brickSoundCount = min(brickSoundCount + 1, 11)
          lastBrickSoundTime = engine.time
        }

        brickToDestroy = brickNode
        break  // can only collide with one brick at a time
      }
    }

    if let brickToDestroy = brickToDestroy {
      bricks.removeObject(brickToDestroy)
      deadBricks.append(brickToDestroy)

      // Move the brick sprite in front of the other bricks.
      brickToDestroy.sprite.drawOrder = 199
      spriteBatch.sortSpritesByDrawOrder()

      var brickIsKilled = false

      if settings.brickScale {
        let tween = tweenPool.scaleToTween()
        tween.target = brickToDestroy
        tween.amount = float2.zero
        tween.duration = settings.brickDestructionDuration
        tween.timingFunction = TimingFunctionQuadraticEaseOut
        tweenPool.add(tween)
        brickIsKilled = true
      }

      if settings.brickDarken {
        brickToDestroy.sprite.color = vectorWithRGB(132, 14, 63)
        brickIsKilled = true
      }

      if settings.brickRotate {
        let tween = tweenPool.rotateToTween()
        tween.target = brickToDestroy
        tween.amount = 360
        tween.duration = settings.brickDestructionDuration
        tweenPool.add(tween)
        brickIsKilled = true
      }

      if settings.brickGravity {
        // Approximate gravity with just a movement tween and ease in.

        let tween = tweenPool.moveToTween()
        tween.target = brickToDestroy
        tween.amount = float2(0, worldSize.y + 100)
        tween.duration = settings.brickDestructionDuration / 2
        tween.timingFunction = TimingFunctionCubicEaseIn
        tweenPool.add(tween)
        brickIsKilled = true
      }

      if settings.brickPush {
        // This pushes the brick up a bit and to the side, based on the
        // ball's current velocity. An alternative way to do this is to
        // give the brick object a velocity property and set it equal to
        // the ball velocity at the time of impact. Then you keep adding
        // gravity to it to make the brick fall. But doing it with two
        // tweens is just as easy...

        let tweenVertical = tweenPool.moveToTween()
        tweenVertical.target = brickToDestroy
        tweenVertical.amount = float2(0, ballNode.velocity.y) * 0.2
        tweenVertical.duration = 0.5
        tweenVertical.timingFunction = TimingFunctionCubicEaseOut
        tweenPool.add(tweenVertical)

        let tweenHorizontal = tweenPool.moveToTween()
        tweenHorizontal.target = brickToDestroy
        tweenHorizontal.amount = float2(ballNode.velocity.x * 0.5, 0) * 0.5
        tweenHorizontal.duration = settings.brickDestructionDuration / 2
        tweenHorizontal.timingFunction = TimingFunctionLinear
        tweenPool.add(tweenHorizontal)

        brickIsKilled = true
      }

      if settings.brickFade {
        let tween = tweenPool.fadeTween()
        tween.target = brickToDestroy.sprite
        tween.startAlpha = 1
        tween.endAlpha = 0
        tween.duration = settings.brickDestructionDuration
        tween.timingFunction = TimingFunctionCubicEaseOut
        tweenPool.add(tween)
        brickIsKilled = true
      }

      // If there are no animations that move the brick off the screen,
      // then simply hide it. This keeps it in the scene graph, but at
      // least you won't see it.
      if !brickIsKilled {
        brickToDestroy.sprite.hidden = true
      }
    }

    if hitBrick {
      self.hitBrick = true
    }

    // Add gravity
    
    if settings.gravity > 0 {
      var newY = newVelocity.y + settings.gravity * 200 * dt
      newY = fminf(newY, 400)
      newVelocity = float2(newVelocity.x, newY)
    }

    // Stretch the ball depending on its speed

    let newScale: float2
    if settings.ballStretch {
      //float length = GLKVector2Length(newVelocity);
      //newScale = GLKVector2Make(1.0f - length/1500.0f, 1.0f + length/1500.0f);

      // This makes the effect more pronounced; we're not taking the sqrt(),
      // so larger distances count much stronger than small distances.
      let lengthSquared = length_squared(newVelocity)
      newScale = float2(1 - lengthSquared/500000, 1 + lengthSquared/500000)
    }
    else  // no stretching
    {
      newScale = float2(1, 1)
    }

    // We cannot set the new scale directly on the ball because there may be
    // tweens active that also change the scale. Instead, figure out by how
    // much the scale should change and "add" that to the existing scale.
    let diff = newScale / ballNode.desiredScale
    ballNode.desiredScale = newScale
    ballNode.scale *= diff

    // Move the ball

    if hitBorder || hitPaddle || hitBrick {
      hitVector = normalize(ballNode.velocity)
    }

    ballNode.position = newPosition
    ballNode.velocity = newVelocity

    // Rotate the ball in the direction it's flying
    
    if settings.ballRotate {
      let rate = settings.ballRotateAnimated ? settings.ballRotateSpeed : 1
      ballNode.rotateToVelocity(ballNode.velocity, rate: rate)
    } else {
      ballNode.angle = 0
    }

    // Extra animations on the ball
    
    if hitBorder || hitPaddle || hitBrick {
      if settings.ballExtraScale {
        // It is possible that the ball hits a new brick while the old
        // animation is still running. Because scale animations are additive,
        // this creates a bigger and bigger ball. That looks cool, but may
        // not always be what you want (the original game doesn't do this).

        if !settings.cumulativeHits {
          tweenPool.remove(forTarget: ballNode, withName: "ballExtraScale", finish: true)
        }

        let tween = tweenPool.scaleFromTween()
        tween.target = ballNode
        tween.amount = float2(2, 2)
        tween.duration = 0.2
        tween.timingFunction = TimingFunctionQuadraticEaseOut
        tween.name = "ballExtraScale"
        tweenPool.add(tween)
      }

      if settings.ballGlow && settings.colorEnabled {
        let tween = tweenPool.tintTween()
        tween.target = ballNode.sprite
        tween.startColor = vectorWithRGB(255, 255, 255)
        tween.endColor = vectorWithRGB(248, 202, 0)
        tween.duration = 1
        tween.timingFunction = TimingFunctionQuadraticEaseOut
        tweenPool.add(tween)
      }

      if settings.ballStretchAnimated && settings.ballStretch {
        tweenPool.remove(forTarget: ballNode, withName: "ballStretchAnimated", finish: true)

        let amounts = [
          float2(1.5, 0.6667),
          float2(0.9, 1.2),
          float2(1.5, 0.6667),
          float2(0.9, 1.2),
          float2(1.5, 0.6667),
          float2(0.9, 1.2),
          float2(1.5, 0.6667),
          float2(1.0, 1.0),
        ]

        var delay: Float = 0
        for t in 0..<8 {
          let tween = tweenPool.scaleFromTween()
          tween.target = ballNode
          tween.amount = amounts[t]
          tween.duration = 0.08
          tween.delay = delay
          tween.waitUntilAfterDelay = (t >= 1)
          tween.timingFunction = TimingFunctionStepped
          tween.name = "ballStretchAnimated"
          tweenPool.add(tween)

          delay += tween.duration
        }
      }
    }
  }

  func updateDeadBricks(dt: Float) {
    var t = 0
    while t < deadBricks.count {
      let brickNode = deadBricks[t]

      if brickNode.position.y > worldSize.y + 50 {
        if let placeholderNode = worldNode.childNode(withName: "Placeholder") {
          if placeholderNode.userData === brickNode.sprite {
            engine.renderQueue.remove(placeholderNode.sprite)
            worldNode.remove(placeholderNode)
          }
        }
        spriteBatch.remove(brickNode.sprite)
        worldNode.remove(brickNode)
        deadBricks.removeObject(brickNode)
      } else {
        t += 1
      }
    }
  }

  func updateColorGlitch() {
    if colorGlitchCounter > 0 {
      colorGlitchCounter += 1
      if colorGlitchCounter < 10 {
        engine.clearColor = randomColor()
      } else {
        colorGlitchCounter = 0
        engine.clearColor = vectorWithRGB(73, 10, 61)
      }
    }
  }
}
