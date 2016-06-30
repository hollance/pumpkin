/* The OpenGL shaders that get compiled into ShaderProgram objects. */

let ColoredVertexShader =
  "attribute vec4 a_position;\n" +
  "attribute vec4 a_color;\n" +
  "\n" +
  "uniform mat4 u_matrix;\n" +
  "\n" +
  "varying lowp vec4 v_color;\n" +
  "\n" +
  "void main(void)\n" +
  "{\n" +
  "  v_color = a_color;\n" +
  "  gl_Position = u_matrix * a_position;\n" +
  "}"

let ColoredFragmentShader =
  "varying lowp vec4 v_color;\n" +
  "\n" +
  "void main(void)\n" +
  "{\n" +
  "  gl_FragColor = v_color;\n" +
  "}"

let TexturedVertexShader =
  "attribute vec4 a_position;\n" +
  "attribute vec4 a_color;\n" +
  "attribute vec2 a_texCoord;\n" +
  "\n" +
  "uniform mat4 u_matrix;\n" +
  "\n" +
  "varying lowp vec4 v_color;\n" +
  "varying mediump vec2 v_texCoord;\n" +
  "\n" +
  "void main(void)\n" +
  "{\n" +
  "  v_color = a_color;\n" +
  "  v_texCoord = a_texCoord;\n" +
  "  gl_Position = u_matrix * a_position;\n" +
  "}"

let TexturedFragmentShader =
  "varying lowp vec4 v_color;\n" +
  "varying mediump vec2 v_texCoord;\n" +
  "\n" +
  "uniform sampler2D u_sampler;\n" +
  "\n" +
  "void main(void)\n" +
  "{\n" +
  "  gl_FragColor = texture2D(u_sampler, v_texCoord) * v_color;\n" +
  "}"
