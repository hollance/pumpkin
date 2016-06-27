import AVFoundation

/*
 * For playing a sound effect. Simple wrapper around AVAudioPlayer.
 */
public class SoundEffect {
  private var player: AVAudioPlayer?

  public init(filename: String) {
		guard let url = NSBundle.mainBundle().URLForResource(filename, withExtension: "") else {
			print("Could not find file \(filename)")
			return
		}

    do {
      player = try AVAudioPlayer(contentsOfURL: url)
      player?.prepareToPlay()
    } catch {
      print("Error loading sound effect \(filename): \(error)")
    }
  }

  public func play() {
    player?.stop()
    player?.play()
  }
}
