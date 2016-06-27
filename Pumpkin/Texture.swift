//import simd
import GLKit
import OpenGLES

/*
 * Can load PNG, PVR, and PVR.gz textures.
 */
public class Texture {

  /*
   * Whether this texture's alpha channel is premultiplied into the RGB channels.
   * Determines the blend mode that will be used when drawing this texture.
   */
  public var premultipliedAlpha = true

  /* The internal OpenGL name of the texture. */
  public var name: GLuint {
    return info?.name ?? 0
  }

  /* The size of the texture in points. */
  public var contentSize: GLKVector2 {
    if let info = info {
      return GLKVector2Make(Float(info.width), Float(info.height))
    } else {
      return GLKVector2Make(0, 0)
    }
  }

  private var info: GLKTextureInfo?

  //TODO: init?

  public init(filename: String) {
    if let path = NSBundle.mainBundle().pathForResource(filename, ofType: "png") {
      info = loadTextureFromFile(path)
    }
//		if (path == nil)
//			path = [[NSBundle mainBundle] pathForResource:filename ofType:@"pvr"];
//
//		if (path != nil)
//		{
//			_info = [self loadTextureFromFile:path];
//		}
//		else
//		{
//			path = [[NSBundle mainBundle] pathForResource:filename ofType:@"pvr.gz"];
//			if (path != nil)
//				_info = [self loadGzippedTextureFromFile:path];
//		}
  }

  deinit {
    var textureName = name
    if textureName != 0 {
      glDeleteTextures(1, &textureName)
    }
  }

  private func loadTextureFromFile(path: String) -> GLKTextureInfo? {
    glGetError();  // clear any previous errors or loading will fail

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

/*
- (GLKTextureInfo *)loadGzippedTextureFromFile:(NSString *)path
{
	NSData *data = [self loadCompressedPVR:path];
	if (data == nil)
		return 0;

	glGetError();  // clear any previous errors or loading will fail

	NSDictionary * options = @{ GLKTextureLoaderApplyPremultiplication: @NO };
	NSError *error;
	GLKTextureInfo *info = [GLKTextureLoader textureWithContentsOfData:data options:options error:&error];
	if (info == nil)
	{
		PPLog(@"Error loading texture: %@", [error description]);
		return 0;
	}

	glBindTexture(GL_TEXTURE_2D, 0);
	return info;
}

- (NSData *)loadCompressedPVR:(NSString *)path
{
	// Based on code from:
	// http://www.codeandweb.com/blog/2011/05/03/loading-gzip-compressed-pvr-textures-without-realloc

	gzFile inFile = gzopen([path UTF8String], "rb");
	if (inFile == NULL)
	{
		PPLog(@"Cannot open '%@'", path);
		return nil;
	}

	// Load the PVR header. The byte order is ok for Intel + ARM.
	PVRTexHeader header;
	if (gzread(inFile, &header, sizeof(header)) != sizeof(header))
	{
		gzclose(inFile);
		PPLog(@"Cannot read PVR header");
		return nil;
	}

	// Check PVR magic cookie.
	if (header.pvrTag != 559044176)
	{
		gzclose(inFile);
		PPLog(@"Not a PVR file");
		return nil;
	}

	// Allocate memory for the complete texture.
	size_t size = header.dataLength + sizeof(header);
	char *data = malloc(size);
	if (data == NULL)
	{
		gzclose(inFile);
		PPLog(@"Out of memory");
		return nil;
	}

	// Copy the PVR header.
	memcpy(data, &header, sizeof(header));

	// Read the rest of the file.
	if (gzread(inFile, data + sizeof(header), header.dataLength) != (int)header.dataLength)
	{
		gzclose(inFile);
		PPLog(@"Failed to load PVR data");
		return nil;
	}

	gzclose(inFile);

	return [NSData dataWithBytesNoCopy:data length:size];
}
*/
}
