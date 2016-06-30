import UIKit
import OpenGLES
import simd

public func logOpenGLError(file: String = #file, line: UInt = #line) {
  let err = glGetError()
  if err != 0 {
    print(String(format: "*** OpenGL error 0x%04X in %@:%d", err, file, line))
  }
}

/*! Responsible for setting up and managing OpenGL state. */
internal class OpenGLBackend: RenderBackend {
  internal let eaglLayer: CAEAGLLayer
  internal let viewportSize: float2
  internal var clearColor = float4(0, 0, 0, 1)
  internal var modelviewMatrix = float4x4.identity

  private var projectionMatrix = float4x4.identity
  private let screenScale: Float
	private var context: EAGLContext!
  private var framebuffer: GLuint = 0
  private var colorRenderbuffer: GLuint = 0
  private var texturedShader: ShaderProgram!
  private var coloredShader: ShaderProgram!
  private var renderContext = RenderContext()

  internal init(layer: CAEAGLLayer) {
		eaglLayer = layer
		viewportSize = float2(Float(layer.bounds.width), Float(layer.bounds.height))
		screenScale = Float(UIScreen.mainScreen().scale)

    setUpContext()
    setUpBuffers()
    setUpProjection()
    setUpShaders()
    setUpInitialState()

		renderContext.texturedShader = texturedShader
		renderContext.coloredShader = coloredShader

		logOpenGLError()
		//printOpenGLInfo()
  }

  deinit {
    if EAGLContext.currentContext() == context {
      EAGLContext.setCurrentContext(nil)
    }
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
    glGenRenderbuffers(1, &colorRenderbuffer)
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderbuffer)

    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
    glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), colorRenderbuffer)

    eaglLayer.drawableProperties = [
      kEAGLDrawablePropertyRetainedBacking : false,
      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
		]

    context.renderbufferStorage(Int(GL_RENDERBUFFER), fromDrawable: eaglLayer)
  }

  private func setUpProjection() {
    let width = viewportSize.x * screenScale
    let height = viewportSize.y * screenScale

    glViewport(0, 0, GLsizei(width), GLsizei(height))

    let a = 2 / width
    let b = 2 / height

    projectionMatrix = float4x4([
      [ a,  0,  0, 0, ],
      [ 0, -b,  0, 0, ],   // -b flips the vertical axis
      [ 0,  0, -1, 0, ],
      [ -1, 1, -1, 1  ]   // moves (0,0) into top-left corner
    ])

    // Scale up for Retina
    projectionMatrix = projectionMatrix * float4x4(uniformScale: screenScale)
  }

  private func setUpShaders() {
  	texturedShader = ShaderProgram(vertexSource: TexturedVertexShader, fragmentSource: TexturedFragmentShader)
  	coloredShader = ShaderProgram(vertexSource: ColoredVertexShader, fragmentSource: ColoredFragmentShader)
  }

  private func setUpInitialState() {
    glEnable(GLenum(GL_BLEND))
    glEnable(GLenum(GL_CULL_FACE))

    modelviewMatrix = float4x4.identity
  }

  private func printOpenGLInfo() {
    print(String(format: "OpenGL vendor: %s", glGetString(GLenum(GL_VENDOR))))
    print(String(format: "OpenGL renderer: %s", glGetString(GLenum(GL_RENDERER))))
    print(String(format: "OpenGL version: %s", glGetString(GLenum(GL_VERSION))))
  	print(String(format: "Supported OpenGL extensions: %s", glGetString(GLenum(GL_EXTENSIONS))))
  }

  internal func update(dt: Float) {
    // nothing to do here
  }

  internal func render(renderQueue: RenderQueue) {
    glClearColor(clearColor.x, clearColor.y, clearColor.z, clearColor.w)
    glClear(GLenum(GL_COLOR_BUFFER_BIT))

    renderContext.matrix = projectionMatrix * modelviewMatrix
    renderQueue.render(renderContext)

    context.presentRenderbuffer(Int(GL_RENDERBUFFER))
  }
}
