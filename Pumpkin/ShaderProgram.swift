import OpenGLES

/*! Encapsulates a shader program consisting of a vertex and fragment shader. */
public class ShaderProgram {

  private(set) public var programName: GLuint = 0

  public struct Attributes {
    public let position: GLuint = 0
    public let texCoord: GLuint = 1
    public let color: GLuint = 2
  }

  public struct Uniforms {
    public var matrix: GLuint = 0
    public var sampler: GLuint = 0
  }

  private(set) public var attributes = Attributes()
  private(set) public var uniforms = Uniforms()

  public init(vertexSource: String, fragmentSource: String) {
		let vertexShader = compileShaderOfType(GLenum(GL_VERTEX_SHADER), fromSource: vertexSource)
		let fragmentShader = compileShaderOfType(GLenum(GL_FRAGMENT_SHADER), fromSource: fragmentSource)

		programName = buildProgramWithShaders([vertexShader, fragmentShader])

		uniforms.matrix = getUniformLocation("u_matrix")
		uniforms.sampler = getUniformLocation("u_sampler")

    logOpenGLError()
  }

  deinit {
    glDeleteProgram(programName)
  }

  private func getUniformLocation(name: String) -> GLuint {
    let result = glGetUniformLocation(programName, name)
    return result >= 0 ? GLuint(result) : 0
  }

  private func compileShaderOfType(shaderType: GLenum, fromSource source: String) -> GLuint {
    let shaderHandle = glCreateShader(shaderType)

    var utf8 = (source as NSString).UTF8String
    //print(String(format: "Shader source code:\n%s", utf8))

    glShaderSource(shaderHandle, 1, &utf8, nil)
    glCompileShader(shaderHandle)

    var status: GLint = GL_FALSE
    glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &status)
    if status == GL_FALSE {
      print("Error compiling shader: \(getShaderInfoLog(shaderHandle))")
      exit(1)
    }

    return shaderHandle
  }

  private func getShaderInfoLog(shader: GLuint) -> String {
    var length: GLint = 0
    glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &length)

    var str = [GLchar](count: Int(length) + 1, repeatedValue: GLchar(0))
    var size: GLsizei = 0
    glGetShaderInfoLog(shader, GLsizei(length), &size, &str)

    return String.fromCString(str)!
  }

  private func buildProgramWithShaders(shaders: [GLuint]) -> GLuint {
    let programHandle = glCreateProgram()

    for shaderName in shaders {
      glAttachShader(programHandle, shaderName)
    }

    glBindAttribLocation(programHandle, attributes.position, "a_position")
    glBindAttribLocation(programHandle, attributes.texCoord, "a_texCoord")
    glBindAttribLocation(programHandle, attributes.color, "a_color")

    glLinkProgram(programHandle)

    var status: GLint = GL_FALSE
    glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &status)
    if status == GL_FALSE {
      print("Error linking program: \(getProgramInfoLog(programName))")
      exit(1)
    }

    for shaderName in shaders {
      glDetachShader(programHandle, shaderName)
      glDeleteShader(shaderName)
    }

    return programHandle
  }

  private func getProgramInfoLog(program: GLuint) -> String {
    var length: GLint = 0
    glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &length)

    var str = [GLchar](count: Int(length) + 1, repeatedValue: GLchar(0))
    var size: GLsizei = 0
    glGetProgramInfoLog(program, GLsizei(length), &size, &str)

    return String.fromCString(str)!
  }
}
