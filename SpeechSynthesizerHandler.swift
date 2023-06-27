//
//  SpeechSynthesizerHandler.swift
//  Talkie
//
//  Created by Clif on 14/06/2023.
//

import Foundation
import AVFoundation
import SwiftUI

class SpeechSynthesizerHandler: NSObject, AVSpeechSynthesizerDelegate, ObservableObject {
  public var audioBufferPlayer: AudioBufferPlayer!
  var viewModel: ViewModel
  @State var speechSynthesizer: AVSpeechSynthesizer
  @Published var isSpeaking = false

  public var messageQueue: [MessageRow] = []


  init(viewModel: ViewModel, audioBufferPlayer: AudioBufferPlayer) {
    self.viewModel = viewModel
    self.audioBufferPlayer = audioBufferPlayer
    self.speechSynthesizer = AVSpeechSynthesizer()
    super.init()
    self.speechSynthesizer.delegate = self // Now `self` can be a delegate
  }

  func speak(messageRow: MessageRow) {
    print("Speak function called")  // Log Statement
    if self.speechSynthesizer.isSpeaking {
	 self.speechSynthesizer.stopSpeaking(at: .immediate)
    }
    self.messageQueue.append(messageRow)
    if !isSpeaking {
	 print("Not currently speaking, processing next message")  // Log Statement
	 processNextMessage()
    } else {
	 print("Already speaking, appending to messageQueue")  // Log Statement
    }
    audioBufferPlayer.addToBuffer(messageRow.responseText ?? "")
  }

  public func processNextMessage() {
    print("Processing next message. Messages left: \(self.messageQueue.count)")
    if !self.messageQueue.isEmpty {
	 isSpeaking = true
	 let messageRow = self.messageQueue.removeFirst()
	 let utterance = AVSpeechUtterance(string: messageRow.responseText ?? "")
	 //	 guard let selectedCharacter = characterViewModel.selectedCharacter else { return }
	 //	 checkVoiceAvailability(voiceIdentifier: selectedCharacter.voiceIdentifier)
	 //	 utterance.voice = AVSpeechSynthesisVoice(identifier: selectedCharacter.voiceIdentifier)
	 // Use a default voice identifier instead
	 utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // Change this to a voice identifier that suits your app

	 utterance.voice = AVSpeechSynthesisVoice()

	 self.speechSynthesizer.delegate = self // Update this line
	 self.speechSynthesizer.speak(utterance) // Update this line
    } else {
	 isSpeaking = false
    }
  }
  
  @MainActor
  func stopSpeaking() {
    if self.speechSynthesizer.isSpeaking {
	 self.speechSynthesizer.stopSpeaking(at: .word)
    }
//    self.stopMessages()  // Add this line to stop processing messages
//    self.messageQueue.removeAll()
//    audioBufferPlayer.reset()
    self.isSpeaking = false
  }

  //  func stopSpeaking() {
  //    speechSynthesizer.stopSpeaking(at: .word)
  //    self.messageQueue.removeAll()

  //  }
////
//  func stopMessages() {
////    self.messageQueue.removeAll()
//  }


  //AVSpeechSynthesizerDelegate methods

  @objc public func speechSynthesizerDidFinish(_ notification: Notification) {
//    self.processNextMessage()
  }

//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
////    self.processNextMessage()
//    //    processNextMessage()
//  }
//
//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
//    print("Paused speaking")
//  }
//
//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
//    print("Resumed speaking")
//  }
//
//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
//    print("Started speaking")
//  }
//
//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
//    print("Cancelled speaking")
//  }

  // Other AVSpeechSynthesizer related methods here

  //  @MainActor
  //  func pauseSpeaking() {
  //    print("PAUSESPEAKING, isSpeaking: \(speechSynthesizer.isSpeaking)")
  //    if speechSynthesizer.isSpeaking {
  //	 print("isSpeechPaused TRUE, wasSpeaking: \(speechSynthesizer.isSpeaking)")
  //	 speechSynthesizer.pauseSpeaking(at: .word)
  //	 self.isSpeechPaused = true
  //	 print("Speech Paused, isSpeechPaused: \(self.isSpeechPaused), isSpeaking: \(speechSynthesizer.isSpeaking)")
  //    }
  //  }
  //
  //  @MainActor
  //  func resumeSpeaking() {
  //    print("RESUMESPEAKING, isPaused: \(self.isSpeechPaused)")
  //    if self.isSpeechPaused {
  //	 print("isSpeechPaused FALSE, wasPaused: \(self.isSpeechPaused)")
  //	 speechSynthesizer.continueSpeaking()
  //	 self.isSpeechPaused = false
  //	 print("Speech Resumed, isSpeechPaused: \(self.isSpeechPaused), isSpeaking: \(speechSynthesizer.isSpeaking)")
  //    }
  //  }
}
