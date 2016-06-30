/*
  These settings control how the game looks and what it does.

  In the Objective-C version of this project you could change these settings
  during runtime from an in-game menu, but for the Swift version I've kept them
  as compile-time constants. Maybe one day I'll add the menu back in.
*/

struct Settings {
  // Time: by how much to speed up or slow down the time
  var timeScale: Float = 1

  // Color
  var colorEnabled = false

  // Tweening
  var tweeningEnabled = false
  var tweenYPosition = false
  var tweenRotation = false
  var tweenScale = false
  var tweenAlpha = false
  var tweenBorders = false
  var tweenLogo = false
  var tweeningDuration: Float = 0
  var tweeningDelay: Float = 0
  var easingEquation = 0

  // Strech and Squeeze
  var paddleStretch = false
  var ballRotate = false
  var ballRotateAnimated = false
  var ballRotateSpeed: Float = 0
  var ballStretch = false
  var ballExtraScale = false
  var ballStretchAnimated = false
  var ballGlow = false
  var brickJelly = false
  var cumulativeHits = false

  // Gravity
  var gravity: Float = 0

  // Sound
  var soundBorder = false
  var soundBrick = false
  var soundPaddle = false
  var musicEnabled = false

  // Personality
  var paddleFace = false
  var paddleEyeScale: Float = 1
  var paddleEyeSeparation: Float = 0
  var paddleLookAtBall = false
  var paddleMouthScale: Float = 1

  // Bouncy Lines
  var bouncyLinesEnabled = false

  // Screen Shake
  var screenShakeEnabled = false
  var screenShakePower: Float = 0
  var screenShakeDuration: Float = 0
  var screenTumbleEnabled = false
  var screenZoomEnabled = false
  var colorGlitchEnabled = false

  // Balls
  var ballTrailEnabled = false
  var maxBalls = 1
  var ballType = 0   // 0, 1, 2

  // Brick Destruction
  var brickDestructionDuration: Float = 0
  var brickScale = false
  var brickDarken = false
  var brickRotate = false
  var brickGravity = false
  var brickPush = false
  var brickFade = false
  var brickShatter = false

  // Particles
  var particleBallCollision = false
  var particleBrickShatter = false
  var particlePaddleCollision = false
}

var settings = Settings()

extension Settings {
  /* Enable all the effects. Goin' krazy! */
  mutating func allEffects() {
    colorEnabled = true

    tweeningEnabled = true
    tweenYPosition = true
    tweenRotation = true
    tweenScale = true
    tweenAlpha = true
    tweenBorders = true
    tweenLogo = true
    tweeningDuration = 0.8
    tweeningDelay = 0.4
    easingEquation = 2

    paddleStretch = true
    ballRotate = true
    ballRotateAnimated = true
    ballRotateSpeed = 0.25
    ballStretch = true
    ballExtraScale = true
    ballStretchAnimated = true
    ballGlow = true
    brickJelly = true
    cumulativeHits = true

    soundBorder = true
    soundBrick = true
    soundPaddle = true
    musicEnabled = true

    paddleFace = true
    paddleEyeScale = 0.8
    paddleEyeSeparation = 45
    paddleLookAtBall = true
    paddleMouthScale = 0.8

    bouncyLinesEnabled = true

    screenShakeEnabled = true
    screenShakePower = 10
    screenShakeDuration = 3
    screenTumbleEnabled = true
    screenZoomEnabled = true
    colorGlitchEnabled = true

    ballTrailEnabled = true
    maxBalls = 10
    ballType = 0

    brickDestructionDuration = 2
    brickScale = true
    brickDarken = true
    brickRotate = true
    brickGravity = true
    brickPush = true
    brickFade = true
    brickShatter = true

    particleBallCollision = true
    particleBrickShatter = true
    particlePaddleCollision = true
  }

  /* Enable the most useful effects without going nuts... */
  mutating func commonEffects() {
    timeScale = 1
    colorEnabled = true

    tweeningEnabled = true
    tweenYPosition = true
    tweenRotation = true
    tweenScale = true
    tweeningDuration = 0.8
    tweeningDelay = 0.4
    easingEquation = 2

    paddleStretch = true
    ballRotate = true
    ballRotateAnimated = false
    ballRotateSpeed = 0.25
    ballStretch = true
    ballExtraScale = true
    ballStretchAnimated = true
    ballGlow = true
    brickJelly = true
    cumulativeHits = false

    paddleFace = true
    paddleEyeScale = 0.8
    paddleEyeSeparation = 45
    paddleLookAtBall = true
    paddleMouthScale = 0.8

    screenShakeEnabled = true
    screenShakePower = 10
    screenShakeDuration = 3

    brickDarken = true
    brickGravity = true
  }

  /* Here you can make your own customizations. This function is called
     when the game starts. */
  mutating func customizeEffects() {
    allEffects()

    musicEnabled = false
    maxBalls = 1
    ballType = 2
    tweenLogo = true
  }
}
