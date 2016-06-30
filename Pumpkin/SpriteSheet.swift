import Foundation
import UIKit
import GLKit

/*!
  Contains a list of sprite frame rectangles.

  When using Zwoptex, the file must be saved as "Zwoptex Flash (.plist)".
  When using Texture Packer, the file format must be "cocos2d-original".
*/
public class SpriteSheet {
  private var frames: [String: SpriteFrame] = [:]
  private var textureWidth: Float = 0
  private var textureHeight: Float = 0

  public init(filename: String) {
    if let path = NSBundle.mainBundle().pathForResource(filename, ofType: "plist"),
           zwoptex = NSDictionary(contentsOfFile: path) {

      if let texture = zwoptex["texture"] as? NSDictionary {
        textureWidth = texture["width"]! as! Float
        textureHeight = texture["height"]! as! Float
      }

      let scale = Float(UIScreen.mainScreen().scale)

      if let framesDict = zwoptex["frames"]! as? [String: AnyObject] {
        for (key, value) in framesDict {

          // strip off ".png"
          var s: NSString = (key as NSString).stringByDeletingPathExtension

          // strip off @2x
          if s.hasSuffix("@2x") {
            s = s.substringToIndex(s.length - 3)
          }

          let dict = value as! [String: AnyObject]

          let x = dict["x"]! as! Float
          let y = dict["y"]! as! Float
          let w = dict["width"]! as! Float
          let h = dict["height"]! as! Float

          var spriteFrame = SpriteFrame()
          spriteFrame.contentSize = GLKVector2Make(w/scale, h/scale)

          let nx = x / textureWidth
          let ny = y / textureHeight
          let nw = w / textureWidth
          let nh = h / textureHeight
          spriteFrame.texCoords = GLKVector4Make(nx, ny, nx + nw, ny + nh)

          frames[s as String] = spriteFrame
        }
      }
    }
  }

  public subscript(name: String) -> SpriteFrame? {
    return frames[name]
  }
}

extension SpriteSheet: CustomStringConvertible {
  public var description: String {
    return "rects \(frames)"
  }
}
