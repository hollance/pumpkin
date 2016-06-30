import UIKit

/*! View that knows how to render Metal content. */
public class MetalView: UIView {
  public override class func layerClass() -> AnyClass {
    return CAMetalLayer.self
  }

  public var metalLayer: CAMetalLayer {
    return layer as! CAMetalLayer
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

		//contentScaleFactor = UIScreen.mainScreen().scale
		//layer.opaque = true
  }
}
