
//
//  AudioBufferPlayer.swift
//  TalkieLite
//
//  Created by Clif on 08/05/2023.
//

import Foundation
import Combine
import SwiftUI
import NaturalLanguage
import Intents
import AVFoundation
import MediaPlayer





// ADD SiriKit Media Intents / App Intents for play pause functionality
extension AudioBufferPlayer {
  func handle(intent: INPlayMediaIntent, completion: @escaping (INPlayMediaIntentResponse) -> Void) {
    let userActivity: NSUserActivity? = nil

    guard let playbackSpeed = intent.playbackSpeed else {
	 print("Error: Playback speed is nil")
	 // Handle the error appropriately, e.g., by returning or showing an error message
	 return
    }

    guard let mediaItems = intent.mediaItems else {
	 print("Error: Media items are nil")
	 // Handle the error appropriately, e.g., by returning or showing an error message
	 return
    }

    if intent.playbackSpeed != nil {
	 rate = Float(intent.playbackSpeed!)
    }

    if intent.mediaItems != nil {
	 // Assuming you are getting text in 'identifier' of INMediaItem
	 if let text = intent.mediaItems?.first?.identifier {
	   addToBuffer(text)
	 }

	 
    }

    let response = INPlayMediaIntentResponse(code: .continueInApp, userActivity: userActivity)
    completion(response)
  }
}




// ADD AVQueuePlayer for remote control and buffering to Airplay

// ADD MK Controller and functions from SampleBufferPlayer project

class AudioBufferPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, INPlayMediaIntentHandling {

  static let shared = AudioBufferPlayer()
  weak var viewModel: ViewModel?
  weak var characterViewModel: CharacterViewModel?
  @Published var settingsViewModel: SettingsViewModel?
  @Published var characterSettingsViewModel: CharacterSettingsViewModel?
  @Published var userSettings: UserSettings?
  @Published var isPresented: Bool = false


  @Published var remoteControl: RemoteControl?

  @State var synthesizer: AVSpeechSynthesizer
  var rate: Float = 1.0
  @Published var pitch: Float = 1.0
  @Published var volume: Float = 1.0

  public var buffer: String = ""
  @Published var isPlaying: Bool = false
  
  @Published var currentLine: Int = 0
  private var currentUtterance: AVSpeechUtterance?
  public var voiceIdentifier: String?
  private let bufferThreshold = 100
  private let bufferSizeThreshold = 20 // NEW: Increase the buffer size threshold
  var requestMoreDataCallback: (() -> Void)?
  var completionHandler: (() -> Void)?
  @Published var isSpeaking = false

  public var isStopIssued: Bool = false
  public var isPaused: Bool = false
  public var shouldResume: Bool = false

  let lock = DispatchSemaphore(value: 1)
//  var utteranceQueue = DispatchQueue(label: "com.yourapp.utteranceQueue")
//  let utteranceQueueAccessQueue = DispatchQueue(label: "pro.UXLab.utteranceQueueAccessQueue")
  public var utteranceQueue: [AVSpeechUtterance] = []

  var audioRecordingHandler: AudioRecordingHandler?

  override init() {
    print("AudioBufferPlayer created")
    self.synthesizer = AVSpeechSynthesizer()

    
    super.init()

    // Initialize your AppIntent with the AudioBufferPlayer
    let appIntent = AppIntent(audioBufferPlayer: self)

    let userSettings = self.userSettings ?? UserSettings()

    let isPresentedBinding = Binding<Bool>(
	 get: { self.isPresented ?? false },
	 set: { self.isPresented = $0 }
    )

    let characterViewModel = CharacterViewModel(characterId: "Talkie") // Adjust this as needed
    let characterSettingsViewModel = CharacterSettingsViewModel(characterViewModel: characterViewModel, character: characterViewModel.characters.first!) // Adjust this as needed
    let settingsViewModel = SettingsViewModel(isPresented: .constant(false), userSettings: UserSettings(), characterViewModel: characterViewModel, characterSettingsViewModel: characterSettingsViewModel) // Adjust this as needed



    self.remoteControl = RemoteControl(settingsViewModel: settingsViewModel, appIntent: appIntent, audioBufferPlayer: self)

//    let characterSettingsViewModel = CharacterSettingsViewModel(characterViewModel: characterViewModel, character: ViewModel.character)
//    let defaultSettingsViewModel = SettingsViewModel(characterViewModel: characterViewModel, characterSettingsViewModel: characterSettingsViewModel, isPresented: isPresentedBinding, userSettings: userSettings)

    guard let settingsViewModel = self.settingsViewModel else {
	 // Handle the case where settingsViewModel is nil, perhaps by returning early or setting a default value
	 print("Error: settingsViewModel is nil")
	 return
    }

    self.remoteControl = RemoteControl(settingsViewModel: settingsViewModel, appIntent: appIntent, audioBufferPlayer: self)

    self.synthesizer.mixToTelephonyUplink = true
    self.synthesizer.usesApplicationAudioSession = true
//    DispatchQueue.main.async {
//	 self.characterViewModel = CharacterViewModel.shared
//    }
    synthesizer.delegate = self
    setupSynthesizer()
  }


  private func setupRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.addTarget { [unowned self] event in
	 if !self.isPlaying {
	   self.resumeSpeaking()
	   print("RESUMESPEAKING")
	   remoteControl?.updateNowPlayingInfo()
	   return .success
	 }
	 return .commandFailed
    }

    commandCenter.pauseCommand.addTarget { [unowned self] event in
	 if self.isPlaying {
	   self.pauseSpeaking()
	   print("PAUSESPEAKING")
	   remoteControl?.updateNowPlayingInfo()
	   return .success
	 }
	 return .commandFailed
    }
  }

  init(character: Character, viewModel: ViewModel) {
    self.viewModel = viewModel



    self.synthesizer = AVSpeechSynthesizer()
    super.init()
    setupSynthesizer()

    setupRemoteCommandCenter()

    //    AudioManager.shared.prepareAudioSession(category: .ambient, mode: .voiceChat, options: [
    //	 .mixWithOthers,
    //	 .allowBluetooth
    //    ])
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }


//  func voiceIdentifierForCharacter(_ characterId: String) -> AVSpeechSynthesisVoice? {
//    let voiceLanguage: String
//    if let character = characterViewModel?.characters.first(where: { $0.id == characterId }) {
//	 voiceLanguage = character.voiceIdentifier
//    } else {
//	 voiceLanguage = "com.apple.speech.synthesis.voice.Zarvox" // fallback
//    }
//    let availableVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == voiceLanguage }
//    if let selectedVoice = availableVoices.first {
//	 print("Selected voice: \(selectedVoice.identifier)")
//	 return selectedVoice
//    }
//    return nil
//  }
//
//  func selectVoice(identifier: String) -> AVSpeechSynthesisVoice? {
//    // Here you create the voice
//    let voice = AVSpeechSynthesisVoice(identifier: identifier)
//    return voice
//  }
//
//
//
//
//  func chooseSpeechVoices() -> [AVSpeechSynthesisVoice?] {
//    // List all available voices in en-US language
//    let voices = AVSpeechSynthesisVoice.speechVoices()
//	 .filter({$0.language == "en-US"})
//
//    // split male/female voices
//    let maleVoices = voices.filter({$0.gender == .male})
//    let femaleVoices = voices.filter({$0.gender == .female})
//
//    // pick voices
//    let selectedMaleVoice = maleVoices.first(where: {$0.quality == .premium}) ?? maleVoices.first // premium is only available from iOS 16
//    let selectedFemaleVoice = femaleVoices.first(where: {$0.quality == .enhanced}) ?? femaleVoices.first
//
//    //
//    if selectedMaleVoice == nil && selectedFemaleVoice == nil {
//	 print("Text to speech feature is not available on your device")
//    } else if selectedMaleVoice == nil {
//	 print("Text to speech with Male voice is not available on your device")
//    } else if selectedFemaleVoice == nil {
//	 print("Text to speech with Female voice is not available on your device")
//    }
//
//    return [selectedMaleVoice, selectedFemaleVoice]
//  }
//



  func prepareAudioSession() {
#if os(iOS)
    AudioManager.shared.prepareAudioSession(category: .playback, mode: .voiceChat, options: [
	 .mixWithOthers,
//	 .duckOthers,
	 .allowBluetooth,
	 .defaultToSpeaker
    ])
#else
    AudioManager.shared.prepareAudioSession(category: .playback, mode: .spokenAudio, options: [
	 .mixWithOthers
    ])
#endif
  }

  private func setupSynthesizer() {
    synthesizer.delegate = self
    NotificationCenter.default.addObserver(self, selector: #selector(AudioManager.shared.handleAudioSessionInterruption), name: AVAudioSession.interruptionNotification, object: nil)
  }

  func stopRecording() {
    audioRecordingHandler?.stopRecording()
  }

  func handleContractions(_ text: String) -> String {
    let contractionsMapping: [String: String] = [
	 "I'm": "I am",
	 "I’d": "I would",
	 "I'll": "I will",
	 "I’ve": "I have",
	 "isn't": "is not",
	 "aren't": "are not",
	 "wasn't": "was not",
	 "weren't": "were not",
	 "haven't": "have not",
	 "hasn't": "has not",
	 "hadn't": "had not",
	 "won't": "will not",
	 "wouldn't": "would not",
	 "don't": "do not",
	 "doesn’t": "does not",
	 "didn't": "did not",
	 "can't": "cannot",
	 "couldn’t": "could not",
	 "shouldn't": "should not",
	 "mightn't": "might not",
	 "mustn't": "must not",
	 "you'd": "your would",
	 "you've": "you have",
	 "I'd": "I would",
	 "St. Patrick": "Saint Patrick",
	 "St. Patrick's": "Saint Patricks"
    ]
    var processedText = text
    for (contraction, fullForm) in contractionsMapping {
	 processedText = processedText.replacingOccurrences(of: contraction, with: fullForm)
    }
    return processedText
  }

  func handlePronunciation(_ text: String) -> String {
    let pronunciationMapping: [String: String] = [
	 "you'd": "yewd",
	 "I'd": "eyed",
	 "we'd": "weed",
	 "they'd": "thade",
	 "he'd": "heed",
	 "she'd": "sheed",
	 "it'd": "itid",
	 "would've": "wouldove",
	 "could've": "couldove",
	 "should've": "shouldove",
	 "might've": "mightove",
	 "must've": "mustove",
	 "I'm": "I am",
	 "don't": "dont",
	 "AI": "eh eye",
	 "Dr.": "Doctor",
	 "St. Patrick": "Saint Patrick",
	 "St. Patrick's": "Saint Patricks"
    ]
    var processedText = text
    for (key, value) in pronunciationMapping {
	 processedText = processedText.replacingOccurrences(of: key, with: value)
    }
    return processedText
  }

  func addToBuffer(_ text: String) {
    lock.wait()
    defer { lock.signal() }
    if isStopIssued {
	 isStopIssued = false
    }
    let textWithHandledPronunciation = handlePronunciation(text)
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = textWithHandledPronunciation
    let options: NLTagger.Options = [.omitWhitespace, .joinNames]
    tagger.enumerateTags(in: textWithHandledPronunciation.startIndex..<textWithHandledPronunciation.endIndex, unit: .sentence, scheme: .lexicalClass, options: options) { tag, tokenRange in
	 let sentence = String(textWithHandledPronunciation[tokenRange])
	 buffer += sentence
	 if bufferShouldBePlayed() {
	   // split buffer into sentences
	   let sentences = buffer.split(whereSeparator: { ".!?".contains($0) })
	   for sentence in sentences {
		let processedText = preprocessText(String(sentence))
		let utterance = AVSpeechUtterance(string: processedText)
		//	   if let voice = voiceIdentifierForCharacter(viewModel?.selectedCharacterId ?? "0") {
		//		utterance.voice = voice
		//	   }
		//	   utterance.postUtteranceDelay = 0.0
		utteranceQueue.append(utterance)
	   }
	   buffer = ""
	   if !synthesizer.isSpeaking && !isPaused && !isStopIssued {
		playNextUtterance()
	   }
	 }
	 return true
    }
  }

  public func playNextUtterance() {
    // If stop is issued or clear messages is requested, stop.
    if isStopIssued || ((viewModel?.isClearMessagesRequested) != nil) {
	 isPlaying = false
	 return
    }
//    if isPlaying {
//	 return
//    }
    isPlaying = true
    if !utteranceQueue.isEmpty {
	 let utterance = utteranceQueue.removeFirst()
	 utterance.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
	 utterance.rate = 1.0
	 utterance.pitchMultiplier = 1.0
	 utterance.volume = 1.0
//	 utterance.rate = self.rate
//	 utterance.pitchMultiplier = self.pitch
//	 utterance.volume = self.volume
	 utterance.preUtteranceDelay = 0.0
	 utterance.postUtteranceDelay = 0.0
	 utterance.prefersAssistiveTechnologySettings = true

	 print("\(utterance.speechString)")
	 synthesizer.speak(utterance)
    } else if !synthesizer.isSpeaking {
	 // Exit condition: if no more data and synthesizer isn't speaking, stop
	 if let requestMoreData = requestMoreDataCallback {
	   requestMoreData()
	 } else {
	   stopSpeaking()
	   print("isStopIssued: \(isStopIssued)")
	   return
	 }
	 // Wait for more data or continue to stop speaking
	 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
	   if self.isStopIssued {  // check if stop was issued before continuing
		return
	   }
	   self.playNextUtterance()
	 }
    }
    if utteranceQueue.count <= bufferThreshold, let requestMoreData = requestMoreDataCallback {
	 if isStopIssued || ((viewModel?.isClearMessagesRequested) != nil) {
	   return
	 }
	 requestMoreData()
    }
  }


  func clearBuffer() {
//    lock.wait()
//    defer { lock.signal() }
    print("CLEARBUFFER")
//    buffer = ""
    self.utteranceQueue.removeAll()
  }

  //  func initializeBufferAndSelectVoice(_ text: String) {
  //    // Select the voice once at the start of the buffer
  //    if let voice = voiceIdentifierForCharacter(viewModel?.selectedCharacterId ?? "0") {
  //	 // Set the voice for the utterances
  //	 for utterance in utteranceQueue {
  //	   utterance.voice = voice
  //	 }
  //    }
  //    // Add the text to the buffer
  //    addToBuffer(text)
  //  }
  //

  private func bufferShouldBePlayed() -> Bool {
    let sentenceEndCharacters: Set<String> = [".", "!", "?", ",", "\n"]
    if let lastChar = buffer.last.map(String.init), sentenceEndCharacters.contains(lastChar) {
	 return true
    }
    return false
  }

  private func preprocessText(_ text: String) -> String {
    let processedText = text.replacingOccurrences(of: "I'", with: "I ")
	 .replacingOccurrences(of: "I’", with: "I ")
	 .replacingOccurrences(of: "^I ", with: "i ", options: .regularExpression)
    let characterSet = CharacterSet(charactersIn: ",.") // Add any other punctuation marks you want to handle
    let components = processedText.components(separatedBy: characterSet)
    let cleanedText = components.joined(separator: " ") // Add spaces around punctuation marks
    return cleanedText
  }

  //  private func preprocessText(_ text: String) -> String {
  //    // Just return the text as is, no need to handle "I'" or "I’"
  //    return text
  //  }

  private func splitTextIntoChunks(_ text: String) -> [String] {
    var chunks: [String] = []
    let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
    for sentence in sentences {
	 let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
	 guard !trimmedSentence.isEmpty else { continue }
	 chunks.append(trimmedSentence + ".")
    }
    return chunks
  }

  func speakResponse(_ text: String, completion: @escaping () -> Void) {
    addToBuffer(text)
    completionHandler = completion
  }

  func reset() {
    print("RESET") // Add this line
    buffer = ""
    utteranceQueue = []  // clear the utterance queue
    isStopIssued = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
	 if self.synthesizer.isSpeaking {
	   self.synthesizer.stopSpeaking(at: .word)
	 }
	 self.isPlaying = false
    }
    clearBuffer() // Clears the buffer
    isPlaying = false
    isStopIssued = true
        utteranceQueue.removeAll() // Add this line to clear the utterance queue
    utteranceQueue = []
  }

//  public func finishPlaying() {
//    isPlaying = false
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
//	 self.synthesizer.stopSpeaking(at: .immediate)
//    }
//    completionHandler?()
//    completionHandler = nil
//  }

  func stopSpeaking() {
    // Stops the synthesizer
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
	 if self.synthesizer.isSpeaking {
	   self.synthesizer.stopSpeaking(at: .word)
	 }
    }
    isStopIssued = true // Moved this line up
    print("STOPSPEAKING")
    // Clears the utterance queue

    print("Utterance queue cleared")
    isPlaying = false
//    currentUtterance = nil
    utteranceQueue = []
    utteranceQueue.removeAll()
    clearBuffer()

    completionHandler?()
    completionHandler = nil
  }

  // Precise control methods
  func pauseSpeaking() {
    print("PAUSESPEAKING, isPlaying: \(isPlaying)")
    if isPlaying {
	 print("isSpeechPaused FALSE, wasSpeaking: \(isPlaying)")
	 isPaused = true // Set this immediately
	 shouldResume = false
	 DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
	   self.synthesizer.pauseSpeaking(at: .immediate)
	   self.isPlaying = false
	   print("Speech Paused, isPlaying: \(self.isPlaying)")
	 }
    }
  }
  func resumeSpeaking() {
    print("RESUMESPEAKING")
    if isPaused {
	 isPaused = false
	 if !synthesizer.continueSpeaking() {
	   shouldResume = true
	 } else {
	   DispatchQueue.main.async {
		self.isPlaying = true
	   }
	 }
    }
  }

  func adjustRate(_ rate: Float) {
    guard let currentUtterance = currentUtterance else { return }
    pauseSpeaking()
    currentUtterance.rate = rate
    resumeSpeaking()
  }

  func adjustPitch(_ pitch: Float) {
    guard let currentUtterance = currentUtterance else { return }
    pauseSpeaking()
    currentUtterance.pitchMultiplier = pitch
    resumeSpeaking()
  }

  func adjustVolume(_ volume: Float) {
    guard let currentUtterance = currentUtterance else { return }
    pauseSpeaking()
    currentUtterance.volume = volume
    resumeSpeaking()
  }

  func muteUnmuteVolume(isMuted: Bool) {
    if isMuted {
	 volume = 0.0 // Mute
    } else {
	 volume = 1.0 // Unmute
    }
  }

  // AVSpeechSynthesizerDelegate methods

  //  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
  //    DispatchQueue.main.async { [weak self] in
  //	 self?.isSpeaking = false
  //	 self?.playNextUtterance()
  //	 if self?.utteranceQueue.isEmpty == true {
  //	   self?.finishPlaying()
  //	 }
  //    }
  //  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    print("Speech started")
    DispatchQueue.main.async {
	 self.isPlaying = true
    }
  }



  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    print("Speech finished")
        DispatchQueue.main.async {
    self.isPlaying = false
        }
    print("isPlaying: \(isPlaying)")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
	 if self.shouldResume {
	   self.shouldResume = false
	   self.playNextUtterance()
	 } else if let requestMoreData = self.requestMoreDataCallback {
	   requestMoreData()
	 }

    }
    if !utteranceQueue.isEmpty {  // If there are more utterances in the queue
	 playNextUtterance()  // Start the next utterance
    }
  }


//  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
//    self.isPlaying = false  // Update isPlaying when an utterance finishes
//    if !utteranceQueue.isEmpty || !isPaused || !isStopIssued {  // If there are more utterances in the queue
//	 playNextUtterance()  // Start the next utterance
//    }
//  }


  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    print("Speech paused")
    DispatchQueue.main.async {
	 self.isPlaying = false
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
    print("Speech continued")
    DispatchQueue.main.async {
	 self.isPlaying = true
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    print("Speech cancelled")
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
    let text = utterance.speechString
//    let subString = (text as NSString).substring(with: characterRange)
//    print("\(subString)")
    //    print("\(characterRange)")
  }
}
