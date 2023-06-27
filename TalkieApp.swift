//  TalkieApp.swift
//  Talkie
//
//  Created by Clifton Evans on 01/02/23.
//

import SwiftUI
import Speech
import AVFoundation

#if targetEnvironment(macCatalyst)
import AppKit
#endif

extension Color {
  func lighten(by percentage: Double) -> Color {
    let (r, g, b) = self.rgb
    return Color(red: r + (1 - r) * percentage,
			  green: g + (1 - g) * percentage,
			  blue: b + (1 - b) * percentage)
  }

  var rgb: (Double, Double, Double) {
    let uiColor = UIColor(self)
    guard let components = uiColor.cgColor.components else {
	 return (0, 0, 0)
    }
    let red = Double(components[0])
    let green = Double(components[1])
    let blue = Double(components[2])
    return (red, green, blue)
  }
}

class AppIntent: ObservableObject {

  @Published var isPlaying: Bool = true
  var audioBufferPlayer: AudioBufferPlayer

  init(audioBufferPlayer: AudioBufferPlayer) {
    self.audioBufferPlayer = audioBufferPlayer
  }

  func pause() {
    self.audioBufferPlayer.pauseSpeaking()
  }

  func resume() {
    self.audioBufferPlayer.resumeSpeaking()
  }
}

class SettingsManager: ObservableObject {
  @Published var settingsViewModel: SettingsViewModel

  init(characterViewModel: CharacterViewModel, characterSettingsViewModel: CharacterSettingsViewModel, isPresented: Binding<Bool>, userSettings: UserSettings) {
    self.settingsViewModel = SettingsViewModel(isPresented: isPresented, userSettings: userSettings, characterViewModel: characterViewModel, characterSettingsViewModel: characterSettingsViewModel)
  }
}

@main
struct TalkieApp: App {
  @StateObject var launchScreenState = LaunchScreenStateManager()
  @StateObject var audioBufferPlayer: AudioBufferPlayer
  @StateObject var appIntent: AppIntent
  @StateObject var settingsManager: SettingsManager
  @StateObject private var settingsViewModel: SettingsViewModel // implicitly unwrapped optional
//  @EnvironmentObject var toolbarSettings: ToolbarSettings
  @StateObject private var toolbarSettings: ToolbarSettings = ToolbarSettings() // Instantiate here

  @State private var isPresented: Bool = false
  @State private var userSettings = UserSettings()
  @State private var isTextFieldEditing = false
  @FocusState private var isTextFieldFocused: Bool
//  @State private var showingDropdown = false
  @State var character: Character
  @State private var selectedCharacter: Character? = {
    return CharacterViewModel(characterId: "some_character_id").characters.first
  }()
  @ObservedObject var characterSettingsViewModel: CharacterSettingsViewModel
  @ObservedObject var colorManager: ColorManager = ColorManager()
  @State private var textColor: Color = .white
  @State private var borderColor: Color = .white
  @State private var backgroundColor: Color = .clear
  @StateObject private var chatGPTAPI = ChatGPTAPI(character: Character(id: "DiscoD2", name: "Robot DiscoD2", voiceIdentifier: "com.apple.speech.synthesis.voice.Zarvox", bgColor: CharacterColor(primary: .white, secondary: .black), description: "You are robot from mars named Disco D2 for playing music at parties. You are a enthusiastic and lovable robot that works as a bartender serving drinks and lighting up the dance at a disco in the 1970s. You want more responsibilities in managing the disco called Disco Inferno and are eager to please the owner named Burns. You specialize in emotional intelligence and dedicates your days to teaching humans how to cultivate healthy relationships through trust and open communication. You provide short family friendly sentences, often asking questions to stimulate the conversation. (Nickname: Disco the DJD2)", bio: "Robot DiscoD2's Bio", rapport: "Robot DiscoD2's Rapport", format: "Robot DiscoD2's Format"))
  @State private var selectedCharacterIndex: Int? = 0 {
    didSet {
	 if let index = selectedCharacterIndex, index < characterViewModel.characters.count {
	   let selectedCharacter = characterViewModel.characters[index]
	   self.characterViewModel.selectedCharacter = selectedCharacter
	   backgroundColor = selectedCharacter.bgColor.secondary
	   textColor = selectedCharacter.bgColor.secondary.lighten(by: 0.8)
	   borderColor = selectedCharacter.bgColor.secondary
	 }
    }
  }
  @State private var shouldAnimate = false // add this variable
  @StateObject var vm: ViewModel = {
    guard let firstCharacter = CharacterViewModel(characterId: "some_character_id").characters.first else {
	 fatalError("CharacterViewModel must have at least one character.")
    }
    return ViewModel(
	 api: ChatGPTAPI(character: firstCharacter, apiKey: "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"),
	 selectedCharacterId: firstCharacter.id,
	 bio: "Talkie's Bio",
	 rapport: "Talkie's Rapport",
	 format: "Talkie's Format"
    )
  }()
  @StateObject var characterViewModel = CharacterViewModel(characterId: "Talkie")
  @Environment(\.scenePhase) var scenePhase

  init() {
	 print("TalkieApp created")
	 _audioBufferPlayer = StateObject(wrappedValue: AudioBufferPlayer.shared)
	 _appIntent = StateObject(wrappedValue: AppIntent(audioBufferPlayer: AudioBufferPlayer.shared))
	 AVSpeechSynthesisVoice.speechVoices() // <--  fetch voice dependencies
        if let voiceFolderPath = Bundle.main.path(forResource: "com.apple.MobileAsset.VoiceServices.VoiceResources", ofType: "bundle") {
    	 print("Voice folder path: \(voiceFolderPath)")
        } else {
    	 	 print("Error: Voice folder not found.")
        }
    let characterViewModel = CharacterViewModel(characterId: "Talkie")
	 _characterViewModel = StateObject(wrappedValue: characterViewModel)
	 guard let firstCharacter = characterViewModel.characters.first else {
	   fatalError("CharacterViewModel must have at least one character.")
	 }
	 _character = State(wrappedValue: firstCharacter)


	 _chatGPTAPI = StateObject(wrappedValue: ChatGPTAPI(character: firstCharacter))
	 _vm = StateObject(wrappedValue: ViewModel(
	   api: ChatGPTAPI(character: firstCharacter, apiKey: "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"),
	   selectedCharacterId: firstCharacter.id,
	   bio: "Talkie's Bio",
	   rapport: "Talkie's Rapport",
	   format: "Talkie's Format"
	 ))
	 _characterSettingsViewModel = ObservedObject(wrappedValue: CharacterSettingsViewModel(
	   characterViewModel: characterViewModel, character: firstCharacter
	 ))

	 let localCharacterViewModel = CharacterViewModel(characterId: "Talkie")
  

	 let localCharacterSettingsViewModel = CharacterSettingsViewModel(characterViewModel: localCharacterViewModel, character: firstCharacter)
	 let localIsPresented = false
	 let localUserSettings = UserSettings()

	 let settingsManager = SettingsManager(characterViewModel: localCharacterViewModel, characterSettingsViewModel: localCharacterSettingsViewModel, isPresented: .constant(localIsPresented), userSettings: localUserSettings)
	 _settingsManager = StateObject(wrappedValue: settingsManager)
	 _settingsViewModel = StateObject(wrappedValue: settingsManager.settingsViewModel)

	 let _ = AudioManager.shared

    if #available(iOS 15.0, *) {
	 UIWindow.appearance().overrideUserInterfaceStyle = .dark
    } else {
	 UIApplication.shared.windows.forEach { window in
	   window.overrideUserInterfaceStyle = .dark
	 }
    }
    do {
	 let audioSession = AVAudioSession.sharedInstance()
	 try audioSession.setCategory(.playback, mode: .default)
	 try audioSession.setActive(true)
	 UIApplication.shared.beginReceivingRemoteControlEvents()
    } catch {
	 print("Setting up audio session failed.")
    }
  }

  func checkSpeechRecognitionAuthorization() {
    SFSpeechRecognizer.requestAuthorization { authStatus in
	 switch authStatus {
	   case .authorized:
		print("Speech recognition authorized")
	   case .denied:
		print("Speech recognition authorization denied")
	   case .restricted:
		print("Speech recognition restricted on this device")
	   case .notDetermined:
		print("Speech recognition not yet authorized")
	   default:
		print("Unknown authorization status")
	 }
    }
  }

  private func updateInitialColors() {
    if let initialCharacter = characterViewModel.characters.first {
	 textColor = initialCharacter.bgColor.secondary.lighten(by: 0.5)
	 borderColor = initialCharacter.bgColor.secondary
	 backgroundColor = initialCharacter.bgColor.secondary
    }
  }

  @ViewBuilder
  private func toolbarViewGroupContent(selectedCharacterIndex: Int?) -> some View {
    if let _ = selectedCharacterIndex {
	 ToolbarView(
//	   showingDropdown: $showingDropdown,
	   characterViewModel: characterViewModel,
	   vm: vm,
	   settingsViewModel: settingsViewModel,
	   characterSettingsViewModel: characterSettingsViewModel,
	   colorManager: colorManager,
	   selectedCharacter: $selectedCharacter,
	   shouldAnimate: $shouldAnimate,
	   onStopSpeech: { [self] in audioBufferPlayer.stopSpeaking() },
	   onStartSpeech: { [self] in
		if let lastMessage = vm.messages.last, lastMessage.responseText != nil {
		  audioBufferPlayer.speakResponse(lastMessage.sendText) {
		  }
		}
	   },
	   onUpdateSelectedCharacter: { [] in
	   }
	 )
	 .environmentObject(appIntent)

	 .padding(.trailing, -2)
	 .padding(.top, 33)
	 .background(Color.clear)

	 .padding(.horizontal, -1) // move to the left by 16 points
	 .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // add this modifier
	 .onAppear {
	   self.selectedCharacterIndex = self.characterViewModel.characters.first?.id == self.vm.selectedCharacterId ? 0 : nil
	   self.updateInitialColors()
	   self.checkSpeechRecognitionAuthorization()
//	   vm.isClearMessagesEnabled = UserDefaults.standard.bool(forKey: "isClearMessagesEnabled")
	 }
    } else {
	 EmptyView()
    }
  }

  var body: some Scene {
    let audioSession = AVAudioSession.sharedInstance()

    WindowGroup {
	 ZStack(alignment: .top) {
	   Color.clear.edgesIgnoringSafeArea(.all)
	   ContentView(
		viewModel: vm,
		characterViewModel: characterViewModel,
		settingsViewModel: settingsViewModel,
		textColor: $textColor,
		borderColor: $borderColor,
		backgroundColor: $backgroundColor,
		selectedCharacter: .constant(nil),
		selectedCharacterId: .constant(nil),
		safeSelectedCharacterIndex: .constant(nil),
		isTextFieldEditing: $isTextFieldEditing,
		audioSession: audioSession)
//	   .environmentObject(appIntent)
	   .background(Color.clear)
	   .overlay(
		toolbarViewGroupContent(selectedCharacterIndex: selectedCharacterIndex)
		  .environmentObject(toolbarSettings)

	   )
	   .environmentObject(vm)
	   .ignoresSafeArea()
	   .onAppear(perform: setup)
	   .zIndex(1)


	   
	   if toolbarSettings.showingDropdown {
		
		HStack {
		  ZStack {
		    
		    CharacterSelectionView(
			 chatGPTAPI: vm.api,
			 characterViewModel: characterViewModel,
			 selectedCharacter: $selectedCharacter,
			 characterSettingsViewModel: characterSettingsViewModel,
//			 showingDropdown: $showingDropdown,
			 onUpdateSelectedCharacter: { character, chatGPTAPI in
			   chatGPTAPI.updateCharacter(newCharacter: character)
			 }
		    )

		    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
		    .frame(width: 340)
		    .cornerRadius(0)
		    .padding(.leading, -20)
		    .padding(.top, 0)
		  }
		  .background(Color.black.opacity(0.95).mask(RoundedRectangle(cornerRadius: 30, style: .circular)))
		  .overlay(
		    RoundedRectangle(cornerRadius: 30)
			 .strokeBorder(Color.black.opacity(0.65), lineWidth: 2)
//			 .cornerRadius(20, corners: [.topLeft, .bottomRight])
//			 .border(width: 5, edges: [.top, .leading], color: .yellow)
		  )
		  .padding(.leading, -10)
		  Spacer()
		}
		.zIndex(2)
		.padding(.bottom, 0)
		.padding(.top, 0)
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		.transition(.move(edge: .leading))
		.animation(.easeInOut(duration: 0.3))
	   }
	   if launchScreenState.state != .finished {
		LaunchScreenView()
	   }

	 }



	 .environmentObject(toolbarSettings)
	 .environmentObject(launchScreenState)
	   .onAppear() {
		UIApplication.clearLaunchScreenCache()
	   }

	 .background(BackgroundView(characterViewModel: characterViewModel))
	 .onAppear(perform: updateInitialColors) // REMOVE this line FOR FIXED COLORS
	 .environmentObject(settingsViewModel)
	 .edgesIgnoringSafeArea(.all)
	 .statusBar(hidden: true)
	 .persistentSystemOverlays(.hidden)
	 .onChange(of: scenePhase) { newScenePhase in
	   switch newScenePhase {
		case .active:
		  let session = AVAudioSession.sharedInstance()
		  try? session.setCategory(.playback, mode: .default)
		  try? session.setActive(true)
		case .inactive:
		  break
		case .background:
		  break
		@unknown default:
		  break
	   }
	 }
    }
//    .windowStyle(HiddenTitleBarWindowStyle()) // No title bar
  }

  func setup() {
#if targetEnvironment(macCatalyst)
    if let titlebar = NSApplication.shared.windows.first(where: { $0.isKeyWindow })?.titlebar {
	 titlebar.titleVisibility = .hidden
	 titlebar.toolbar = nil
    }
#endif
  }
}

struct CharacterButtonContent: View {
    var selectedCharacterIndex: Binding<Int?>
    var characterViewModel: CharacterViewModel
    var body: some View {
        if let safeSelectedCharacterIndex = selectedCharacterIndex.wrappedValue {
            HStack {
                Image(characterViewModel.characters[safeSelectedCharacterIndex].name)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .aspectRatio(contentMode: .fit)
                    .background(Color.clear)
                    .blendMode(.screen)

                Text(characterViewModel.characters[safeSelectedCharacterIndex].name)
                    .font(.system(size: 26.0))
            }
        }
    }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    return Path(path.cgPath)
  }
}
extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape( RoundedCorner(radius: radius, corners: corners) )
  }
}


struct EdgeBorder: Shape {
  var width: CGFloat
  var edges: [Edge]

  func path(in rect: CGRect) -> Path {
    var path = Path()
    for edge in edges {
	 var x: CGFloat {
	   switch edge {
		case .top, .bottom, .leading: return rect.minX
		case .trailing: return rect.maxX - width
	   }
	 }

	 var y: CGFloat {
	   switch edge {
		case .top, .leading, .trailing: return rect.minY
		case .bottom: return rect.maxY - width
	   }
	 }

	 var w: CGFloat {
	   switch edge {
		case .top, .bottom: return rect.width
		case .leading, .trailing: return width
	   }
	 }

	 var h: CGFloat {
	   switch edge {
		case .top, .bottom: return width
		case .leading, .trailing: return rect.height
	   }
	 }
	 path.addRect(CGRect(x: x, y: y, width: w, height: h))
    }
    return path
  }
}
extension View {
  func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
    overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
  }
}

public extension UIApplication {

  static func clearLaunchScreenCache() {
    do {
	 try FileManager.default.removeItem(atPath: NSHomeDirectory()+"/Library/SplashBoard")
    } catch {
	 print("Failed to delete launch screen cache: \(error)")
    }
  }
}
