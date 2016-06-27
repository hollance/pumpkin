import AVFoundation

/*
 * For playing background music.
 */
public class Music {
  private var player: AVAudioPlayer?

  private(set) public var isPlaying = false

  public var volume: Float {
    get { return player?.volume ?? 0 }
    set { player?.volume = volume }
  }

  public init(filename: String) {
		guard let url = NSBundle.mainBundle().URLForResource(filename, withExtension: "") else {
			print("Could not find file \(filename)")
			return
		}

    do {
      player = try AVAudioPlayer(contentsOfURL: url)
      player?.numberOfLoops = -1
      player?.prepareToPlay()
    } catch {
      print("Error loading music \(filename): \(error)")
    }
  }

  public func play() {
    if !isPlaying {
      player?.play()
      isPlaying = true
    }
  }

  public func stop() {
    if isPlaying {
      player?.stop()
      isPlaying = false
    }
  }

  public func rewind() {
    stop()
    player?.currentTime = 0
    play()
  }
}
