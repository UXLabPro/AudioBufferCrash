//
//  ViewModel.swift
//  Talkie
//
//  Created by Clifton Evans on 02/02/23.
//

import Foundation
import SwiftUI
import AVKit
import AVFoundation  // text to speech
import Combine
#if os(iOS) || os(macOS)
import Speech
#endif

class ViewModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

//  @SceneStorage("isClearMessagesEnabled") public var isClearMessagesEnabled: Bool?
//
//  var settingsState = SettingsState()
//  var isClearMessagesEnabled: Bool = false

  static let character = Character(id: "0",
					   name: "Talkie",
					   voiceIdentifier: "",
					   bgColor: CharacterColor(primary: Color("TalkiePrimary"), secondary: Color("TalkieSecondary")),
					   description: "",
					   bio: "Character Bio",
					   rapport: "Character Rapport",
					   format: "Character Format")
  static let shared = ViewModel(api: ChatGPTAPI(character: character), selectedCharacterId: "0", bio: character.bio, rapport: character.rapport, format: character.format)

  var bio: String
  var rapport: String
  var format: String
  var characterViewModel: CharacterViewModel

  @Published var characterSettingsViewModel: CharacterSettingsViewModel?
  @Published var userSettings: UserSettings?
  @Published var isPresented: Bool = false

  @Published var isMicButtonPressed = false
  private let audioEngine = AVAudioEngine()
#if os(iOS) || os(macOS)
  @Published var recognitionTask: SFSpeechRecognitionTask?
  private let speechRecognizer = SFSpeechRecognizer()
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
#endif
  @Published var isInteractingWithChatGPT = false
  @Published var messages: [MessageRow] = []
  @Published var inputMessage: String = ""
  @Published var systemMessage: Message?
  @Published var debouncedMessage: String = ""
  @Published var message: [Message] = []
  private var chatAPI: ChatGPTAPI?

  @Published var isTextFieldFocused: Bool = false
  @Published var currentTextID: Int?
  @Published var micButtonOffset: CGFloat = 0
  @Published var micButtonScale: CGFloat = 1.0
  @Published var bounceAnimationProgress: CGFloat = 0.0
  @Published var isAudioPlaying = false
  @Published var isSendTappedCalled = false // send tapped is for the textfield and other apps.
  @Published var isSpeechPaused = false
  @Published var isSpeaking = false
  @Published var stopMessages = false

  @Published var remoteControl: RemoteControl
  @Published var settingsViewModel: SettingsViewModel

  public var isClearMessagesRequested: Bool = false

  var task: Task<Void, Never>?


  let debounceHandleMicButtonTapped = Debouncer(delay: 0.2)
#if os(iOS) || os(macOS) || os(tvOS)
  private var audioManager: AudioManager!

  private lazy var speechSynthesizer: AVSpeechSynthesizer = {
    return audioManager.getSpeechSynthesizer()
  }()
#endif
  private var audioSession: AVAudioSession {
    return audioManager.getAudioSession()
  }
  private var cancellables = Set<AnyCancellable>()
  private let responseTextSubject = PassthroughSubject<String, Never>()
  public var audioBufferPlayer: AudioBufferPlayer!
  //  private let audioSession = AVAudioSession.sharedInstance()


  @Published private(set) var api: ChatGPTAPI
  public var selectedCharacterId: String // Add this line

  // HANDLERS
//  var chatAPIHandler: ChatAPIHandler
  
  var audioRecordingHandler: AudioRecordingHandler?
  var speechSynthesizerHandler: SpeechSynthesizerHandler?
  var speechRecognitionHandler: SpeechRecognitionHandler?

  init(api: ChatGPTAPI, enableSpeech: Bool = true, selectedCharacterId: String, bio: String, rapport: String, format: String) {
    print("ViewModel created")
    self.api = api
    self.selectedCharacterId = selectedCharacterId
    self.bio = bio
    self.rapport = rapport
    self.format = format

    // Initialize properties before using them
    let userSettings = UserSettings() // Initialize as a local variable
    self.characterViewModel = CharacterViewModel(characterId: "Talkie") // Initialize characterViewModel
    let characterSettingsViewModel = CharacterSettingsViewModel(characterViewModel: self.characterViewModel, character: ViewModel.character)
    let settingsViewModel = SettingsViewModel(isPresented: .constant(false), userSettings: userSettings, characterViewModel: self.characterViewModel, characterSettingsViewModel: characterSettingsViewModel)
    let audioBufferPlayer = AudioBufferPlayer.shared
    let appIntent = AppIntent(audioBufferPlayer: audioBufferPlayer)

    // Initialize the rest of the properties
    self.userSettings = userSettings // Assign the local variable to the property
    self.characterSettingsViewModel = characterSettingsViewModel
    self.settingsViewModel = settingsViewModel
    self.remoteControl = RemoteControl(settingsViewModel: settingsViewModel, appIntent: appIntent, audioBufferPlayer: audioBufferPlayer)

    super.init() 

    // Now that all properties are initialized, you can access `self`
    self.audioManager = AudioManager.shared
    speechSynthesizer.delegate = self
    if let character = characterViewModel.characters.first(where: { $0.id == self.selectedCharacterId }) {
	 self.audioBufferPlayer = AudioBufferPlayer.shared
    } else {
	 self.audioBufferPlayer = AudioBufferPlayer.shared
    }
    //    chatAPIHandler = ChatAPIHandler(...)
    audioRecordingHandler = AudioRecordingHandler(viewModel: self, audioBufferPlayer: audioBufferPlayer, audioSession: audioSession)
    lazy var speechSynthesizerHandler: SpeechSynthesizerHandler = {
	 return SpeechSynthesizerHandler(viewModel: self, audioBufferPlayer: audioBufferPlayer)
    }()
    speechRecognitionHandler = SpeechRecognitionHandler(audioBufferPlayer: audioBufferPlayer, viewModel: self, audioRecordingHandler: audioRecordingHandler!, speechSynthesizerHandler: speechSynthesizerHandler)



    //    checkSpeechRecognitionAuthorization()xx
    //    for voice in AVSpeechSynthesisVoice.speechVoices() {
    //	 print(voice)
    //    }
    NotificationCenter.default.addObserver(self, selector: #selector(SpeechSynthesizerHandler.speechSynthesizerDidFinish(_:)), name: Notification.Name("SpeechSynthesizerDidFinish"), object: nil)
    if enableSpeech {
	 responseTextSubject
	   .receive(on: DispatchQueue.main)
	   .sink { [weak self] _ in
		DispatchQueue.main.async {
		  self?.audioBufferPlayer.stopRecording()
		  //		  self?.audioBufferPlayer.reset()
		  if let lastMessage = self?.messages.last {
		    self?.audioBufferPlayer.addToBuffer(lastMessage.responseText ?? "")
		  }
		  self?.isAudioPlaying = true // Add this line
		}
	   }
	   .store(in: &cancellables)
	 audioBufferPlayer.$isPlaying
	   .receive(on: DispatchQueue.main)
	   .sink { [weak self] isPlaying in
		DispatchQueue.main.async {
		  self?.isAudioPlaying = isPlaying
		}
	   }
	   .store(in: &cancellables)
    }
    $debouncedMessage.assign(to: &$inputMessage)
  }



  func setupAPI(character: Character, apiKey: String = "") {
    chatAPI = ChatGPTAPI(character: character, apiKey: apiKey)
    print("API setup with character: \(character.name)")
  }

  func setupAudioBufferPlayer() {
    AudioBufferPlayer.shared.viewModel = self
  }

  func sendMessage(text: String, role: String) {
    guard let chatAPI = chatAPI else { return }
    Task(priority: .userInitiated) {
	 do {
	   let responseText = try await chatAPI.sendMessage(text, characterDescription: chatAPI.systemMessage.content)
	   self.message.append(Message(role: role, content: text))
	   self.message.append(Message(role: "assistant", content: responseText))
	   print("After sendMessage: \(self.messages)")  // Print statement here
	   if role != "assistant" {
		self.audioBufferPlayer.addToBuffer(responseText)
	   }
	 } catch {
	   print("Error: \(error.localizedDescription)")
	 }
    }
  }

  func checkVoiceAvailability(voiceIdentifier: String) {
    let availableVoices = AVSpeechSynthesisVoice.speechVoices()
    let voiceIsAvailable = availableVoices.contains { voice in
	 return voice.identifier == voiceIdentifier
    }

    print("Voice availability:", voiceIsAvailable)
  }

  func receiveMessage(_ message: Message) {
    if stopMessages {
	 return
    }
    DispatchQueue.main.async {
	 let messageRow = MessageRow(isUser: false, sendText: "", sendImage: "", responseText: message.content, responseImage: "", responseError: "", isInteractingWithChatGPT: false)
	 self.messages.append(messageRow)
	 print("After receiving a message: \(self.messages)")  // Print statement here
	 self.objectWillChange.send()
	 if message.role == "bot" {
	   self.speechSynthesizerHandler?.speak(messageRow: messageRow)
	   // Add a short delay before starting the audio playback
	   DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
		self.audioBufferPlayer.playNextUtterance()
	   }
	 }
    }
  }

  static func createViewModel(character: Character) -> ViewModel {
    let api = ChatGPTAPI(character: character, apiKey: "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")
    let viewModel = ViewModel(api: api, selectedCharacterId: character.id, bio: character.bio, rapport: character.rapport, format: character.format)
    viewModel.audioBufferPlayer = AudioBufferPlayer.shared
    return viewModel
  }

  func updateCharacter(newCharacter: Character) {
    api = ChatGPTAPI(character: newCharacter, apiKey: "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")
    systemMessage = Message(role: "user", content: newCharacter.description)
    objectWillChange.send()
    audioBufferPlayer = AudioBufferPlayer.shared
  }

  let punctuation = CharacterSet(charactersIn: ".!?,:;") // Adjust as needed for the punctuation you care about.



  @MainActor
  public func send(text: String) async {
    isInteractingWithChatGPT = true
    var streamText = ""
    var bufferedText = ""
    var messageRow = MessageRow(
	 isUser: true,
	 sendText: text,
	 sendImage: "profile",
	 responseText: streamText,
	 responseImage: "openai",
	 responseError: nil,
	 isInteractingWithChatGPT: false)

    self.messages.append(messageRow)

    self.task = Task(priority: .userInitiated) {
	 do {
	   let stream = try await api.sendMessageStream(text: text, characterDescription: "")
	   for try await receivedText in stream {
		try Task.checkCancellation()  // Check for task cancellation
		streamText += receivedText
		bufferedText += receivedText
		messageRow.responseText = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
		DispatchQueue.main.async {
		  if let index = self.messages.firstIndex(where: { $0.id == messageRow.id }) {
		    self.messages[index] = messageRow
		  }
		}
		if let lastChar = bufferedText.unicodeScalars.last, punctuation.contains(lastChar) {
		  // Send bufferedText to the audio player and clear the buffer
		  self.audioBufferPlayer.addToBuffer(bufferedText)
		  bufferedText = ""
		}
	   }
	   // Ensure any remaining buffered text gets sent.
	   if !bufferedText.isEmpty {
		self.audioBufferPlayer.addToBuffer(bufferedText)
	   }
	 } catch {
	   if error is CancellationError {
		print("Task was cancelled")
	   } else {
		print("Error: \(error.localizedDescription)")
		messageRow.responseError = error.localizedDescription
	   }
	 }
	 messageRow.isInteractingWithChatGPT = false // Update the original messageRow object
	 DispatchQueue.main.async {
	   if let index = self.messages.firstIndex(where: { $0.id == messageRow.id }) {
		self.messages[index] = messageRow
	   }
	   self.isInteractingWithChatGPT = false
	 }
    }
  }


  // only used in textfield and other apps
  @MainActor
  func sendTapped(text: String, characterViewModel: CharacterViewModel) async {
    print("Send tapped called")
    self.cancelStreamingResponse()
    audioBufferPlayer.stopSpeaking()
    await send(text: text)
    debouncedMessage = ""
  }



  func cancelStreamingResponse() {
    self.task?.cancel()
    self.task = nil
  }


  func resetAudioBufferPlayer() {
    audioBufferPlayer.reset()
  }



  @MainActor
  func clearMessages() {
    print("CLEARMESSAGES in \(#file): \(#line)")
//    if settingsState.isClearMessagesEnabled {
	 // Clear the messages
	 Task {
	   await self.api.deleteHistoryList()
	 }
	 withAnimation {
	   self.messages.removeAll()
	   // Optionally, you can also perform any additional actions
	   // such as deleting the messages from the server or database
	 }
//	     resetAudioBufferPlayer()
//    }
  }

  @MainActor
  func retry(message: MessageRow) {
    Task { [weak self] in
	 guard let index = self?.messages.firstIndex(where: { $0.id == message.id }) else {
	   return
	 }
	 self?.messages.remove(at: index)
	 await self?.send(text: message.sendText)
    }
  }
}
