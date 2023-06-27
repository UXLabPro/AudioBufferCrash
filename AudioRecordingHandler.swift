//
//  AudioRecordingHandler.swift
//  Talkie
//
//  Created by Clif on 14/06/2023.
//

import Foundation
import AVFoundation
import Speech

class AudioRecordingHandler: ObservableObject {
  @Published var isAudioPlaying = false
  private var audioManager: AudioManager!

  public var audioBufferPlayer: AudioBufferPlayer!
  var viewModel: ViewModel



  private let audioEngine = AVAudioEngine()
  private let audioSession: AVAudioSession
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?

  var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()

  init(viewModel: ViewModel, audioBufferPlayer: AudioBufferPlayer, audioSession: AVAudioSession) {
    self.viewModel = viewModel
    self.audioBufferPlayer = audioBufferPlayer
    self.audioSession = audioSession
  }


#if os(iOS) || os(macOS) || os(tvOS)
  func prepareAudioSession() {
    AudioManager.shared.prepareAudioSession(category: .playAndRecord, mode: .voiceChat, options: [
	 .defaultToSpeaker,
	 .allowBluetooth
    ])
  }
#endif

  func startRecording() {
    print("STARTRECORDING")
    // Stop any ongoing text-to-speech playback
    viewModel.resetAudioBufferPlayer()
    self.prepareAudioSession()
    guard let recognizer = speechRecognizer, recognizer.isAvailable else {
	 print("Speech recognition is not available")
	 return
    }
    recognitionTask?.cancel()
    recognitionTask = nil
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    let inputNode = audioEngine.inputNode
    // Set the audio format
    //    let sampleRate = 44100
    //    let channelCount = 1
    //    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: UInt32(channelCount))
    // Set the inputNode's output format
    inputNode.outputFormat(forBus: 0)
    guard let recognitionRequest = recognitionRequest else {
	 fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
    }
    recognitionRequest.shouldReportPartialResults = true
    DispatchQueue.main.async {
	 self.recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
	   guard let self = self else { return }
	   if let result = result {
		DispatchQueue.main.async {
		  // Only update the input message if the mic button is pressed
		  if self.viewModel.isMicButtonPressed {
		    self.viewModel.inputMessage = result.bestTranscription.formattedString
		  }
		}
	   }
	   if error != nil {
		self.stopRecording()
	   }
	 }
    }
    let hardwareSampleRate = audioSession.sampleRate
    let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: hardwareSampleRate, channels: 1, interleaved: false)

    if let recordingFormat = recordingFormat {
	 inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
	   self.recognitionRequest?.append(buffer)
	 }
    } else {
	 print("Unable to create AVAudioFormat for recording")
    }
    //    let recordingFormat = inputNode.outputFormat(forBus: 0)
    //    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
    //      self.recognitionRequest?.append(buffer)
    //    }
    audioEngine.prepare()
    do {
	 try audioEngine.start()
    } catch {
	 print("Unable to start the audio engine:", error.localizedDescription)
    }
  }

  public func stopRecording() {
    print("STOPRECORDING")
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionRequest = nil
    recognitionTask = nil
  }
  // Other AudioManager related methods here
}
