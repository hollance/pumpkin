import OpenGLES

public enum ShaderAttributes: GLuint {
  case position = 0
  case texCoord = 1
  case color    = 2
}

public struct ShaderUniforms {
  public var matrix: GLuint = 0
  public var sampler: GLuint = 0
}

/*! Encapsulates a shader program consisting of a vertex and fragment shader. */
public class ShaderProgram {

  private(set) public var programName: GLuint = 0
  private(set) public var uniforms = ShaderUniforms()

  public init(vertexSource: String, fragmentSource: String) {
		let vertexShader = compileShaderOfType(GLenum(GL_VERTEX_SHADER), fromSource: vertexSource)
		let fragmentShader = compileShaderOfType(GLenum(GL_FRAGMENT_SHADER), fromSource: fragmentSource)

		programName = buildProgramWithShaders([vertexShader, fragmentShader])

		uniforms.matrix = GLuint(glGetUniformLocation(programName, "u_matrix"))
    let result = glGetUniformLocation(programName, "u_sampler")
    if result >= 0 {
      uniforms.sampler = GLuint(result)
    }

    logOpenGLError()
  }

  deinit {
    glDeleteProgram(programName)
  }

  private func compileShaderOfType(shaderType: GLenum, fromSource source: String) -> GLuint {
    let shaderHandle = glCreateShader(shaderType)

    var utf8 = (source as NSString).UTF8String
    //print(String(format: "%s", utf8))
    glShaderSource(shaderHandle, 1, &utf8, nil)
    glCompileShader(shaderHandle)

    var status: GLint = GL_FALSE
    glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &status)
    if status == GL_FALSE {
//      var messages = [GLchar](count: 256, repeatedValue: 0)
//      glGetShaderInfoLog(shaderHandle, 255, nil, messages)
//      print(String(format: "Error compiling shader: %s", messages))
      print("Error compiling shader")
      exit(1)
    }

    return shaderHandle
  }

  private func buildProgramWithShaders(shaders: [GLuint]) -> GLuint {
    let programHandle = glCreateProgram()

    for shaderName in shaders {
      glAttachShader(programHandle, shaderName)
    }

    glBindAttribLocation(programHandle, ShaderAttributes.position.rawValue, "a_position")
    glBindAttribLocation(programHandle, ShaderAttributes.texCoord.rawValue, "a_texCoord")
    glBindAttribLocation(programHandle, ShaderAttributes.color.rawValue, "a_color")

    glLinkProgram(programHandle)

    var status: GLint = GL_FALSE
    glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &status)
    if status == GL_FALSE {
//      GLchar messages[256];
//      glGetProgramInfoLog(programHandle, sizeof(messages), NULL, messages);
//      PPLog(@"Error linking program: %s", messages);
      print("Error linking program")
      exit(1)
    }

    for shaderName in shaders {
      glDetachShader(programHandle, shaderName)
      glDeleteShader(shaderName)
    }

    return programHandle
  }
}
