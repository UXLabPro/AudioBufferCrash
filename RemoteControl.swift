//
//  RemoteControl.swift
//  Talkie
//
//  Created by Clif on 29/03/2023.
//



import Foundation
import MediaPlayer
import AVFoundation
import Combine

class RemoteControl: NSObject {

  var settingsViewModel: SettingsViewModel


  let appIntent: AppIntent
  let audioBufferPlayer: AudioBufferPlayer

  var isPlayingCancellable: AnyCancellable?
  var isRecordModeCancellable: AnyCancellable?

  var outputVolume : Float {
    return AVAudioSession.sharedInstance().outputVolume
  }

  var isPlaying: Bool {
    return AudioBufferPlayer.shared.isPlaying
  }


  init(settingsViewModel: SettingsViewModel, appIntent: AppIntent, audioBufferPlayer: AudioBufferPlayer) {
    self.appIntent = appIntent
    self.audioBufferPlayer = audioBufferPlayer
    self.settingsViewModel = settingsViewModel
    super.init()

    // Observe the isPlaying property of the audioBufferPlayer
    self.isPlayingCancellable = self.audioBufferPlayer.$isPlaying
	 .sink(receiveValue: { isPlaying in
	   // Update the appIntent's isPlaying property according to the new value
	   self.appIntent.isPlaying = isPlaying
	 })

    self.isRecordModeCancellable = self.settingsViewModel.$isRecordMode
	 .sink { [weak self] isRecordMode in
	   self?.updateRemoteControlCommands()
	 }

    setupRemoteTransportControls()
    AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: .new, context: nil)
  }

  deinit {
    AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
    self.isPlayingCancellable?.cancel() // cancel the subscription
    self.isRecordModeCancellable?.cancel() // cancel the subscription
  }

  

  func setupRemoteTransportControls() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.addTarget { [unowned self] event in
	 if self.appIntent.isPlaying == false {
	   self.appIntent.resume()
	   updateNowPlayingInfo()
	   return .success
	 }
	 return .commandFailed
    }

    commandCenter.pauseCommand.addTarget { [unowned self] event in
	 if self.appIntent.isPlaying == true {
	   self.appIntent.pause()
	   updateNowPlayingInfo()
	   return .success
	 }
	 return .commandFailed
    }

    commandCenter.togglePlayPauseCommand.addTarget { [unowned self] event in
	 if self.appIntent.isPlaying == false {
	   self.appIntent.resume()
	   updateNowPlayingInfo()
	 } else {
	   self.appIntent.pause()
	   updateNowPlayingInfo()
	 }
	 return .success
    }

//    commandCenter.nextTrackCommand.addTarget { [unowned self] event in
//	 // Increase rate when next track control is pressed.
//	 // Make sure the rate does not exceed the maximum allowed value.
//	 self.audioBufferPlayer.rate = min(self.audioBufferPlayer.rate + 0.1, 2.0)
//	 self.audioBufferPlayer.rate = self.audioBufferPlayer.rate // Apply rate to audioBufferPlayer
//	 self.updateNowPlayingInfo()
//	 return .success
//    }
//
//    commandCenter.previousTrackCommand.addTarget { [unowned self] event in
//	 // Decrease rate when previous track control is pressed.
//	 // Make sure the rate does not go below the minimum allowed value.
//	 self.audioBufferPlayer.rate = max(self.audioBufferPlayer.rate - 0.1, 0.5)
//	 self.audioBufferPlayer.rate = self.audioBufferPlayer.rate // Apply rate to audioBufferPlayer
//	 self.updateNowPlayingInfo()
//	 return .success
//    }

    updateNowPlayingInfo()
  }

//  func updateNowPlayingInfo() {
//    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
//
//

  func updateNowPlayingInfo() {
    var nowPlayingInfo = [String: Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = "Talkie"
    nowPlayingInfo[MPMediaItemPropertyArtist] = "UXLab"
//    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioBufferPlayer.rate
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }


  func updateRemoteControlCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()

    if settingsViewModel.isRecordMode {
	 // Unregister play/pause command
	 commandCenter.playCommand.removeTarget(nil)
	 commandCenter.pauseCommand.removeTarget(nil)

	 // Register record/send command
	 commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
	   // Handle record/send functionality
	   // ...
	   return .success
	 }
    } else {
	 // Unregister record/send command
	 commandCenter.togglePlayPauseCommand.removeTarget(nil)

	 // Register play/pause command
	 commandCenter.playCommand.addTarget { [weak self] event in
	   // Handle play functionality
	   // ...
	   return .success
	 }
	 commandCenter.pauseCommand.addTarget { [weak self] event in
	   // Handle pause functionality
	   // ...
	   return .success
	 }
    }
  }



  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "outputVolume"{
	 print("volume changed! \(self.outputVolume)")
    }
  }
}



//func configureMediaPlayerCommands() {
//  let commandCenter = MPRemoteCommandCenter.shared()
//
//  commandCenter.playCommand.isEnabled = true
//  commandCenter.playCommand.addTarget { [unowned self] event in
//    self.audioBufferPlayer.resumeSpeaking()
//    return .success
//  }
//
//  commandCenter.pauseCommand.isEnabled = true
//  commandCenter.pauseCommand.addTarget { [unowned self] event in
//    self.audioBufferPlayer.pauseSpeaking()
//    return .success
//  }
//
//  // Add other commands (like next, previous) if you need them
//}



//extension ContentView {
//  func configureRemoteCommandCenter() {
//    commandCenter.playCommand.addTarget { [weak self] event in
//	 guard let self = self else { return .commandFailed }
//	 Task {
//	   await self.viewModel.handleMicButtonTapped()
//	 }
//	 return .success
//    }
//
//    commandCenter.pauseCommand.addTarget { [weak self] event in
//	 guard let self = self else { return .commandFailed }
//	 Task {
//	   await self.viewModel.handleMicButtonTapped()
//	 }
//	 return .success
//    }
//  }
//}



////Play pause
//let commandCenter = MPRemoteCommandCenter.shared()
//commandCenter.playCommand.addTarget(handler: { (event) in
//
//    // Begin playing the current track
//  self.appIntent.resume()
//    return MPRemoteCommandHandlerStatus.success
//})
//
//MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { (event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
//
// // middle button (toggle/pause) is clicked
// print("event:", event.command)
//
// return .success
//}
//
//    func setupCommandCenter(viewModel: ViewModel) {
//	 let commandCenter = MPRemoteCommandCenter.shared()
//
//	 commandCenter.playCommand.addTarget { [weak viewModel] _ -> MPRemoteCommandHandlerStatus in
//	   Task { await viewModel?.startDictation() }
//	   return .success
//	 }
//
//	 commandCenter.pauseCommand.addTarget { [weak viewModel] _ -> MPRemoteCommandHandlerStatus in
//	   Task { await viewModel?.stopDictation() }
//	   return .success
//	 }
//    }



// volume buttons
// AudioSessionAddPropertyListener( kAudioSessionProperty_CurrentHardwareOutputVolume , audioVolumeChangeListenerCallback, self );

