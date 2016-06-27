import UIKit
import OpenGLES
//import simd
import GLKit

public func PPLogGLError(file: String = #file, line: UInt = #line) {
  let err = glGetError()
  if err != 0 {
    print(String(format: "*** OpenGL error 0x%04X in %@:%d", err, file, line))
  }
}

/*
 * Passes around objects needed for rendering.
 */
public class RenderContext {

  public var texturedShader: ShaderProgram!
  public var coloredShader: ShaderProgram!

  /*
   * The combined projection and modelview matrices for the game world.
   * The renderer may modify this and should always load this into the shader.
   */
  public var matrix = GLKMatrix4Identity// float4x4(1)
}

/*
 * Describes something that can be added to the render queue.
 */
public protocol Renderer: class {

  /* You can use this to move any animations forward. */
  func update(dt: Float)

  /* Does the actual drawing with Metal. */
  func render(context: RenderContext)
}

/*
 * Responsible for setting up and managing OpenGL state.
 */
public class RenderingEngine {

  /* Dimensions of the visible screen. Equal to the bounds of the OpenGL view. */
  public let viewportSize: CGSize

  /* Fill color for the background. Default is black. */
  public var clearColor = GLKVector4Make(0, 0, 0, 1) //float4(0, 0, 0, 1)

  /* For special effects. */
  public var modelviewMatrix = GLKMatrix4Identity  // float4x4(1)

  /* The items to be rendered. */
  public var renderQueue = RenderQueue()

  private let screenScale: CGFloat

  let eaglLayer: CAEAGLLayer

	var context: EAGLContext!
  var framebuffer: GLuint = 0
  var colorRenderbuffer: GLuint = 0
  var texturedShader: ShaderProgram!
  var coloredShader: ShaderProgram!
  var projectionMatrix = GLKMatrix4Identity  //float4x4()
  var renderContext = RenderContext()

  public init(view: /*MetalView*/ OpenGLView) {
		eaglLayer = view.layer as! CAEAGLLayer
		viewportSize = view.bounds.size
		screenScale = UIScreen.mainScreen().scale

    setUpContext()
    setUpBuffers()
    setUpProjection()
    setUpShaders()
    setUpInitialState()

		renderContext.texturedShader = texturedShader
		renderContext.coloredShader = coloredShader

		PPLogGLError()
		//printOpenGLInfo()
  }

  deinit {
    // TODO: not sure why this doesn't work...
//    if EAGLContext.currentContext == context {
//      EAGLContext.setCurrentContext(nil)
//    }
  }

  private func setUpContext() {
    context = EAGLContext(API: .OpenGLES2)
    if context == nil {
      print("Failed to initialize OpenGL ES 2.0 context")
      exit(1)
    }

    if !EAGLContext.setCurrentContext(context) {
      print("Failed to set current OpenGL context")
      exit(1)
    }
  }

  private func setUpBuffers() {
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderbuffer);

    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer);
    glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), colorRenderbuffer);

    eaglLayer.drawableProperties = [
      kEAGLDrawablePropertyRetainedBacking : false,
      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8  //kEAGLColorFormatRGB565
		]

    context.renderbufferStorage(Int(GL_RENDERBUFFER), fromDrawable: eaglLayer)
  }

  private func setUpProjection() {
    let width = Float(viewportSize.width * screenScale)
    let height = Float(viewportSize.height * screenScale)

//print(width, height, screenScale, NSStringFromCGSize(viewportSize))
    glViewport(0, 0, GLsizei(width), GLsizei(height))

    let a = 2 / width
    let b = 2 / height

//    projectionMatrix = float4x4(rows: [
//      [  a,  0,  0, 0, ],
//      [  0, -b,  0, 0, ],   // -b flips the vertical axis
//      [  0,  0, -1, 0, ],
//      [ -1,  1, -1, 1, ],  // moves (0,0) into top-left corner
//    ])

    projectionMatrix = GLKMatrix4Make(
      a,  0,  0, 0,
      0, -b,  0, 0,   // -b flips the vertical axis
      0,  0, -1, 0,
      -1, 1, -1, 1   // moves (0,0) into top-left corner
    )

    // Scales up for Retina
//    let scaleMatrix = float4x4(diagonal: [Float(screenScale), Float(screenScale), Float(screenScale), 1])
//    projectionMatrix *= scaleMatrix
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, Float(screenScale), Float(screenScale), Float(screenScale))

// should be
// {{0.00195312, 0, 0, 0}, {0, -0.00260417, 0, 0}, {0, 0, -2, 0}, {-1, 1, -1, 1}}
// print("projectionMatrix \(NSStringFromGLKMatrix4(projectionMatrix))")
  }

  private func setUpShaders() {
  	texturedShader = ShaderProgram(vertexSource: TexturedVertexShader, fragmentSource: TexturedFragmentShader)
  	coloredShader = ShaderProgram(vertexSource: ColoredVertexShader, fragmentSource: ColoredFragmentShader)
  }

  private func setUpInitialState() {
    glEnable(GLenum(GL_BLEND))
    glEnable(GLenum(GL_CULL_FACE))

    modelviewMatrix = GLKMatrix4Identity // float4x4(1)
  }

  //#if DEBUG
  private func printOpenGLInfo() {
    print(String(format: "OpenGL vendor: %s", glGetString(GLenum(GL_VENDOR))))
    print(String(format: "OpenGL renderer: %s", glGetString(GLenum(GL_RENDERER))))
    print(String(format: "OpenGL version: %s", glGetString(GLenum(GL_VERSION))))

  //	print(@"Supported OpenGL extensions:");
  //	const char* string = (const char *)glGetString(GL_EXTENSIONS);
  //	if (string != NULL)
  //	{
  //		NSArray *allExtensions = [@(string) componentsSeparatedByString:@" "];
  //		for (NSString *extension in allExtensions)
  //		{
  //			print(@"\t %@", extension);
  //		}
  //	}
  }
  //#endif

  public func update(dt: Float) {
    renderQueue.update(dt)
  }

  public func render() {
    glClearColor(clearColor.x, clearColor.y, clearColor.z, clearColor.w)
    glClear(GLenum(GL_COLOR_BUFFER_BIT))

    //renderContext.matrix = projectionMatrix * modelviewMatrix
    renderContext.matrix = GLKMatrix4Multiply(projectionMatrix, modelviewMatrix)
    renderQueue.render(renderContext)

    context.presentRenderbuffer(Int(GL_RENDERBUFFER))
  }
}
