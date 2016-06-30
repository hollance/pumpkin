import GLKit
import OpenGLES

/*! Can load PNG textures. */
public class Texture {

  /*! Whether this texture's alpha channel is premultiplied into the RGB 
      channels. Determines the blend mode that will be used when drawing 
      this texture. */
  public var premultipliedAlpha = true

  /*! The internal OpenGL name of the texture. */
  public var name: GLuint {
    return info?.name ?? 0
  }

  /*! The size of the texture in points. */
  public var contentSize: GLKVector2 {
    if let info = info {
      return GLKVector2Make(Float(info.width), Float(info.height))
    } else {
      return GLKVector2Make(0, 0)
    }
  }

  private var info: GLKTextureInfo?

  public init(filename: String) {
    if let path = NSBundle.mainBundle().pathForResource(filename, ofType: "png") {
      info = loadTextureFromFile(path)
    }

    /* Note: The Objective-C version could also load PVR and gzipped PVR
       textures. I left that functionality out of this version. */
  }

  deinit {
    var textureName = name
    if textureName != 0 {
      glDeleteTextures(1, &textureName)
    }
  }

  private func loadTextureFromFile(path: String) -> GLKTextureInfo? {
    glGetError()  // clear any previous errors or loading will fail

    do {
      let options = [ GLKTextureLoaderApplyPremultiplication : false ]
      let info = try GLKTextureLoader.textureWithContentsOfFile(path, options: options)

      //glBindTexture(GL_TEXTURE_2D, info.name);
      //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

      glBindTexture(GLenum(GL_TEXTURE_2D), 0)
      return info
    } catch {
      print("Error loading texture: \(error)")
      return nil
    }
  }
}
