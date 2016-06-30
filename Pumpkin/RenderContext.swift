import simd

/*
 * Passes around objects needed for rendering.
 */
public class RenderContext {

  public var texturedShader: ShaderProgram!
  public var coloredShader: ShaderProgram!

  /*! The combined projection and modelview matrices for the game world. The 
      renderer may modify this and should always load this into the shader. */
  public var matrix = float4x4.identity
}
