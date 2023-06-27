//
//  SpeechRecognitionHandler.swift
//  Talkie
//
//  Created by Clif on 14/06/2023.
//

import Foundation
import AVFoundation
import Speech

class SpeechRecognitionHandler: ObservableObject {

  public var audioBufferPlayer: AudioBufferPlayer!
  var viewModel: ViewModel
  var audioRecordingHandler: AudioRecordingHandler
  var speechSynthesizerHandler: SpeechSynthesizerHandler

#if os(iOS) || os(macOS) || os(tvOS)
  private var audioManager: AudioManager!
#endif

  private var audioSession: AVAudioSession {
    return audioManager.getAudioSession()
  }


#if os(iOS) || os(macOS)
  @Published var recognitionTask: SFSpeechRecognitionTask?
  private let speechRecognizer = SFSpeechRecognizer()
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
#endif

  init(audioBufferPlayer: AudioBufferPlayer, viewModel: ViewModel, audioRecordingHandler: AudioRecordingHandler, speechSynthesizerHandler: SpeechSynthesizerHandler) {
    self.audioBufferPlayer = audioBufferPlayer
    self.viewModel = viewModel
    self.audioRecordingHandler = audioRecordingHandler
    self.speechSynthesizerHandler = speechSynthesizerHandler
    self.audioManager = AudioManager.shared // assuming AudioManager has a shared instance, if not initialize it here accordingly
  }


  

  @MainActor
  func handleMicButtonTapped() async {
    if !viewModel.isMicButtonPressed {
	 // Mic button just pressed
	 viewModel.isSendTappedCalled = false
	 viewModel.cancelStreamingResponse()
	 audioBufferPlayer.stopSpeaking()
	 speechSynthesizerHandler.stopSpeaking()
	 viewModel.isMicButtonPressed.toggle()
	 DispatchQueue.main.async { [weak self] in
	   guard let self = self else { return }
	   print("Mic button tapped!")
	   viewModel.inputMessage = ""
	   viewModel.isTextFieldFocused = true
	   Task { @MainActor in
		self.viewModel.isAudioPlaying = false
	   }
	 }
	 DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
	   guard let self = self else { return }
	   if self.audioRecordingHandler != nil {
		print("AudioRecordingHandler is not nil.")
	   } else {
		print("AudioRecordingHandler is nil.")
	   }
	   self.audioRecordingHandler.startRecording()
	 }
    } else {
	 // Mic button released
	 print("SEND")
	 viewModel.isMicButtonPressed.toggle()
	 print("TOGGLED: \(viewModel.isMicButtonPressed)")
	 audioRecordingHandler.stopRecording()
	 audioBufferPlayer.reset()
	 audioBufferPlayer.utteranceQueue.removeAll()
	 print("REMOVEALL")

	 // Call sendTapped here
	 if viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
	   await viewModel.send(text: viewModel.inputMessage)
	   viewModel.isSendTappedCalled = true
	   viewModel.inputMessage = ""  // Clear the input message after sending
	   viewModel.isTextFieldFocused = false
	 }
    }
  }


  // Other SFSpeechRecognitionTask and SFSpeechAudioBufferRecognitionRequest related methods here
}

