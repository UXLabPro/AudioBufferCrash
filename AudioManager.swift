//
//  AudioManager.swift
//  TalkieLite
//
//  Created by Clif on 22/04/2023.
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer

//import Speech
// ADD SiriKit Media Intents?
// ADD Now Playing suypport (airpods controls)

class AudioManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
  static let shared = AudioManager()
  private let audioSession = AVAudioSession.sharedInstance()
  private let speechSynthesizer = AVSpeechSynthesizer()
  var audioBufferPlayer = AudioBufferPlayer.shared


  override init() {
    super.init()

    self.audioBufferPlayer = AudioBufferPlayer()


    do {
	 try audioSession.setActive(true)
    } catch {
	 print("Failed to set up audio session: \(error)")
    }

    

    NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterruption), name: AVAudioSession.interruptionNotification, object: nil)

    speechSynthesizer.delegate = self
#if !os(watchOS)
    prepareAudioSession(category: .playAndRecord, mode: .voiceChat, options: [
	 .defaultToSpeaker,
	 .mixWithOthers,
	 .allowBluetooth
    ])
    do {
	 try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
    } catch let error as NSError {
	 print("AVAudioSession output override error: \(error.localizedDescription)")
    }

    let currentRoute = AVAudioSession.sharedInstance().currentRoute
    for output in currentRoute.outputs {
	 print("Current audio output: \(output.portType.rawValue)")
    }

    AVCaptureDevice.requestAccess(for: .audio) { granted in
	 if granted {
	   // Microphone access granted
	 } else {
	   // Microphone access denied
	 }
    }
#endif
    self.speechSynthesizer.delegate = self


   


  }


  func configureAudioSession(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) {
    prepareAudioSession(category: category, mode: mode, options: options)
  }

  

  func prepareAudioSession(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) {
    do {
	 try AVAudioSession.sharedInstance().setCategory(category, mode: mode, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
	 try AVAudioSession.sharedInstance().setActive(true)
#if !os(watchOS)
//	 updateAudioSessionConfiguration()
#endif
    } catch {
	 print("AVAudioSession setup error: \((error as NSError).localizedDescription)")
    }
  }

  @objc public func handleAudioSessionInterruption(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
		let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
		let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
	 return
    }
    switch type {
	 case .began:
	   audioBufferPlayer.pauseSpeaking()
	 case .ended:
	   if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
		let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
		if options.contains(.shouldResume) {
		  // Insert the audio buffer and begin playing here.
		 let audioBuffer = audioBufferPlayer.buffer
		    audioBufferPlayer.resumeSpeaking()
		}
	   }
	 default:
	   break
    }
  }


  func getSpeechSynthesizer() -> AVSpeechSynthesizer {
    return speechSynthesizer
  }

  func getAudioSession() -> AVAudioSession {
    return audioSession
  }




//    setupAudioSession(category: .playAndRecord, mode: .spokenAudio, options: [.interruptSpokenAudioAndMixWithOthers, .duckOthers, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP, .defaultToSpeaker])

//  func setupAudioSession(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) {
//    do {
//	 try audioSession.setCategory(category, mode: mode, options: options)
//	 try audioSession.setActive(true, options: [])
//
//	 let hardwareSampleRate = audioSession.sampleRate
//	 let hardwareInputChannels = audioSession.inputNumberOfChannels
//	 let hardwareOutputChannels = audioSession.outputNumberOfChannels
//
//	 print("Hardware sample rate: \(hardwareSampleRate)")
//	 print("Hardware input channels: \(hardwareInputChannels)")
//	 print("Hardware output channels: \(hardwareOutputChannels)")
//
//    } catch let error as NSError {
//	 print("AVAudioSession setup error: \(error.localizedDescription)")
//    }
//  }

#if !os(watchOS)
//  func getPreferredSampleRate() -> Double {
//    return audioSession.preferredSampleRate
//  }
//
//  func getPreferredInputChannels() -> Int {
//    return audioSession.preferredInputNumberOfChannels
//  }
//
//  func getPreferredOutputChannels() -> Int {
//    return audioSession.preferredOutputNumberOfChannels
//  }
//
//  func updateAudioSessionConfiguration() {
//    let preferredSampleRate = getPreferredSampleRate()
//    let preferredInputChannels = getPreferredInputChannels()
//    let preferredOutputChannels = getPreferredOutputChannels()
//
//    do {
//	 try audioSession.setPreferredSampleRate(preferredSampleRate)
//	 try audioSession.setPreferredInputNumberOfChannels(preferredInputChannels)
//	 try audioSession.setPreferredOutputNumberOfChannels(preferredOutputChannels)
//    } catch let error as NSError {
//	 print("Error updating audio session configuration: \(error.localizedDescription)")
//    }
//  }
#endif


//  func setVoice(for characterId: String) {
//    let voiceIdentifier: String?
//    switch characterId {
//	 case "Talkie":
//	   voiceIdentifier = "com.apple.speech.synthesis.voice.Cellos" // Replace with the desired voice identifier
//	 case "Partybot":
//	   voiceIdentifier = "com.apple.eloquence.en-GB.Grandpa" // Replace with the desired voice identifier
//	 default:
//	   voiceIdentifier = nil
//    }
//
//    if let voiceIdentifier = voiceIdentifier, let _ = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
//	 if speechSynthesizer.isSpeaking {
//	   speechSynthesizer.stopSpeaking(at: .immediate) // Stop any ongoing speech
//	 }
//	 speechSynthesizer.delegate = nil // Remove any existing delegate
//	 speechSynthesizer.delegate = self // Set the delegate to this AudioManager instance
//
//	 // Create an AVSpeechUtterance instance with a dummy text to set the voice
//	 // let dummyUtterance = AVSpeechUtterance(string: "Dummy text")
//	 // dummyUtterance.voice = voice
//	 // speechSynthesizer.speak(dummyUtterance)
//	 // speechSynthesizer.stopSpeaking(at: .immediate) // Stop the dummy speech
//    }
//  }

//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
////    if synthesizer.isSpeaking {
////	 synthesizer.stopSpeaking(at: .immediate)
////    }
//    DispatchQueue.main.async {
//	 NotificationCenter.default.post(name: Notification.Name("SpeechSynthesizerDidFinish"), object: nil)
//    }
//  }
}
