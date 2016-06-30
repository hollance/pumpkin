import UIKit

/*! View that knows how to render OpenGL content. */
public class OpenGLView: UIView {
  public override class func layerClass() -> AnyClass {
    return CAEAGLLayer.self
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
		contentScaleFactor = UIScreen.mainScreen().scale
		layer.opaque = true
  }
}
