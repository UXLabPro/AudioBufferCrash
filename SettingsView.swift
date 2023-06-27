//  SettingsView.swift
//  Talkie
//
//  Created by Clif on 03/04/2023.

import SwiftUI
import AVFoundation
import PhotosUI

@propertyWrapper
struct UserDefaultsBacked<Value> {
  let key: String
  let defaultValue: Value
  let suite: UserDefaults

  var wrappedValue: Value {
    get {
	 if Value.self == Color.self, let colorString = suite.string(forKey: key) {
	   return Color(colorString) as! Value
	 }
	 return suite.object(forKey: key) as? Value ?? defaultValue
    }
    set {
	 if Value.self == Color.self, let color = newValue as? Color {
	   suite.set(color.toHex(), forKey: key)
	 } else {
	   suite.set(newValue, forKey: key)
	 }
    }
  }
}

extension UserDefaults {
  static let appGroup = UserDefaults(suiteName: "group.com.talkie")!
}

func checkVoiceAvailability() -> [String] {
  let availableVoices = AVSpeechSynthesisVoice.speechVoices()
  return availableVoices.map { voice in
    voice.identifier
  }
}

struct SettingsView: View {
  @StateObject var settingsState = SettingsState()
//  @State private var isClearMessagesEnabled: Bool  // Initialize the property here
//  @SceneStorage("isClearMessagesEnabled") private var isClearMessagesEnabled = false
  @ObservedObject var settingsViewModel: SettingsViewModel
  @State var remoteControl: RemoteControl


  @Binding var isPresented: Bool
  @State private var isPhotoPickerPresented = false
  @State private var selectedImageIndex: Int?
  @ObservedObject var characterViewModel: CharacterViewModel
  @State var character: Character?
  @Binding var selectedCharacter: Character?
  @State var characterSettings: [String: CharacterSettingsViewModel] = [:]
  @State var characterSettingsViewModel: CharacterSettingsViewModel
  @ObservedObject var colorManager: ColorManager

  @ObservedObject var viewModel: ViewModel
  @ObservedObject var audioBufferPlayer = AudioBufferPlayer.shared
  @AppStorage("name") private var name: String = ""
  @AppStorage("age") private var age: String = ""
  //TODO - ADD PHOTO
  @AppStorage("topics") private var topics: String = ""
  //TODO - chagne to format through lifecycle
  @AppStorage("interests") private var interests: String = ""
  @AppStorage("timer") var timer: Data = Data()
  @AppStorage("alarm") var alarm: Data = Data()
  @AppStorage("characterName") var characterName: Data = Data()
  @AppStorage("voiceIdentifier") var voiceIdentifier: Data = Data()
  @AppStorage("characterDescription") var characterDescription: Data = Data()
//  @AppStorage("colorNames") var colorNames: Data = Data()
  @AppStorage("characterImage1") var characterImage1Data: Data?
  @AppStorage("characterImage2") var characterImage2Data: Data?
  @AppStorage("characterImage3") var characterImage3Data: Data?
  @AppStorage("characterImage4") var characterImage4Data: Data?
  @ObservedObject var photosModel: PhotoPickerModel = .init()
  @State private var selectedItem: PhotosPickerItem? = nil
  @State private var selectedImageData: Data? = nil
  // TODO - Set to adjustable primary and secondary.
  // TODO - Set primary and secondary based on image.
//  @StateObject private var settingsViewModel: SettingsViewModel

  @State private var availableVoices: [String] = checkVoiceAvailability()

//  @Binding var isLeftButtonToggled: Bool


  let titleFont = Font.largeTitle.lowercaseSmallCaps()
  let footnoteFont = Font.system(.footnote, design: .serif, weight: .bold)

  var speechSynthesizerHandler: SpeechSynthesizerHandler?

  init(
    viewModel: ViewModel,
    isPresented: Binding<Bool>,
    characterViewModel: CharacterViewModel,
    settingsViewModel: SettingsViewModel,
    selectedCharacter: Binding<Character?>,
    character: Character,
    characterSettingsViewModel: CharacterSettingsViewModel,
    colorManager: ColorManager
  ) {
    self.viewModel = viewModel
    self._isPresented = isPresented
    self.characterViewModel = characterViewModel
    self.settingsViewModel = settingsViewModel
    self._character = State(initialValue: character)
    self._characterSettingsViewModel = State(initialValue: characterSettingsViewModel)
    self._selectedCharacter = selectedCharacter
    self.colorManager = colorManager

    // Initialize remoteControl here
    let appIntent = AppIntent(audioBufferPlayer: AudioBufferPlayer.shared)
    self._remoteControl = State(initialValue: RemoteControl(settingsViewModel: settingsViewModel, appIntent: appIntent, audioBufferPlayer: AudioBufferPlayer.shared))

    //	 lazy var speechSynthesizerHandler: SpeechSynthesizerHandler = {
    //	   return SpeechSynthesizerHandler(viewModel: viewModel, audioBufferPlayer: audioBufferPlayer)
    //	 }()
    
    //    self.settingsState = viewModel.settingsState
    //    self._isClearMessagesEnabled = State(initialValue: settingsState.isClearMessagesEnabled) // Initialize the property here
    
    
  }

  private func saveSettings() {
    let selectedCharacterId = selectedCharacter?.id
    if let selectedCharacterId = selectedCharacterId,
	  var characterSettingsForSelectedCharacter = characterSettings[selectedCharacterId] {

	 // Update the settings for the selected character
	 characterSettingsForSelectedCharacter.characterName = settingsViewModel.name
	 characterSettingsForSelectedCharacter.age = settingsViewModel.age
	 // ... update the rest of the settings ...

	 // Save the updated settings back to the dictionary
	 characterSettings[selectedCharacterId] = characterSettingsForSelectedCharacter

	 // Now save the settings to UserDefaults or wherever you're persisting the data
	 settingsViewModel.saveSettings(
	   name: settingsViewModel.name,
	   age: settingsViewModel.age,
	   topics: settingsViewModel.topics,
	   interests: settingsViewModel.interests,
	   characterName: characterSettingsForSelectedCharacter.characterName,
	   voiceIdentifier: characterSettingsForSelectedCharacter.voiceIdentifier,
	   characterDescription: characterSettingsForSelectedCharacter.characterDescription,
	   primaryColor: characterSettingsForSelectedCharacter.primaryColor,
	   secondaryColor: characterSettingsForSelectedCharacter.secondaryColor
	 )
    }
  }


  func buttonColors(for character: Character) -> CharacterColor? {
    let index = characterViewModel.characters.firstIndex(where: { $0.id == character.id })
    if let index = index, index == characterViewModel.selectedCharacterIndex {
	 //  CharacterColor(primary: Color.white, secondary: Color.black)
    }
    return characterViewModel.characters.first(where: { $0.id == character.id })?.bgColor
  }


  var headerView: some View {
    HStack {
	 VStack {
//	   Text("Profile Setup")
//		.font(.system(size: 20.0, weight: .black, design: .rounded))
//		.foregroundColor(Color.white.opacity(0.65))
//		.padding(.top, 0)
//		.padding(.bottom, 0)
//		.background(Color.black.opacity(0))

	 }
	 Spacer()
	 Button(action: {
	   isPresented.toggle()
	 }) {
	   Image(systemName: "xmark.circle")
		.foregroundColor(Color.white.opacity(0.65))
		.font(.system(size: 35, weight: .thin, design: .rounded))
		.rotationEffect(.degrees(isPresented ? 180 : 0))
	 }
	 .padding(.trailing, 33)
	 .padding(.top, 18)
    }
    .background(Color.black.opacity(0)) // <--- Add this line
								//    .background(RoundedRectangle(cornerRadius: 0).fill(buttonColors(for: selectedCharacter ?? Character(id: "dumyId", name: "dummyName", voiceIdentifier: "dummyVoiceIdentifier", bgColor: CharacterColor(primary: Color.white, secondary: Color.white), description: "dummyDescription", bio: "dummyBio", rapport: "dummyRapport", format: "dummyFormat"))?.primary ?? Color.clear).opacity(0.25))
//    .padding(.top, 10)
//    .padding(.trailing, 20)
//    .padding(.leading, 35)
  }

  var titleView: some View {
    HStack {
	 VStack {
	   Text("Profile Setup")
		.font(.system(size: 20.0, weight: .black, design: .rounded))
		.foregroundColor(Color.white.opacity(0.65))
		.padding(.top, 0)
		.padding(.bottom, 0)
		.background(Color.black.opacity(0))

	 }
	 Spacer()
//	 Button(action: {
//	   isPresented.toggle()
//	 }) {
//	   Image(systemName: "xmark.circle.fill")
//		.foregroundColor(Color.white.opacity(0.10))
//		.font(.system(size: 50, weight: .thin, design: .rounded))
//		.rotationEffect(.degrees(isPresented ? 180 : 0))
//	 }
//	 .padding(.trailing, 3)
//	 .padding(.bottom, 6)
    }
    .background(Color.black.opacity(0)) // <--- Add this line
//    .background(RoundedRectangle(cornerRadius: 0).fill(buttonColors(for: selectedCharacter ?? Character(id: "dumyId", name: "dummyName", voiceIdentifier: "dummyVoiceIdentifier", bgColor: CharacterColor(primary: Color.white, secondary: Color.white), description: "dummyDescription", bio: "dummyBio", rapport: "dummyRapport", format: "dummyFormat"))?.primary ?? Color.clear).opacity(0.25))
    .padding(.bottom, -5)
    .padding(.top, -20)
    .padding(.leading, 35)
  }

  var settingsForm: some View {
    ScrollView {
	 VStack (spacing: 15) {

	   headerView

//	   ActionSettingsView(viewModel: viewModel, characterViewModel: characterViewModel)
//		.padding(.top, -15)
//		.padding(.vertical, 0)
//	   ActionSettingsView(viewModel: viewModel, characterViewModel: characterViewModel)

	   titleView


	   UserSettingsView(settingsViewModel: settingsViewModel, characterViewModel: characterViewModel, remoteControl: remoteControl, availableVoices: .constant(availableVoices))
		.padding(.horizontal, 20)
//		.padding(.vertical, 10)

	   // I'm using dummy @State variables as an example.
	   // You should replace them with appropriate @State or @Binding variables based on your code logic.
	   //		@State var shouldAnimate: Bool = false
	   //		@State var showingDropdown: Bool = false
	   CharacterSettingsView(
		isPresented: $isPresented,
		characterViewModel: characterViewModel,
		selectedCharacter: $selectedCharacter,
		viewModel: viewModel,
		availableVoices: $availableVoices,
		settingsViewModel: settingsViewModel,
		colorManager: colorManager
		//		  shouldAnimate: $shouldAnimate,
		//		  showingDropdown: $showingDropdown
	   ).disabled(true)
//		.opacity(0.3)
	   .padding(.horizontal, 20)
//	   .padding(.vertical, 10)
	   .onAppear {
		characterSettingsViewModel.character = selectedCharacter
	   }

	   //	   Section(header: Text("")) {
	   //		HStack {
	   //		  Text("Timer")
	   //		    .font(.system(size: 18.0, weight: .bold, design: .rounded))
	   //		  DatePicker("", selection: $settingsViewModel.timer, displayedComponents: .hourAndMinute)
	   //		    .font(.system(size: 20.0))
	   //		  Spacer()
	   //		  Text("Alarm")
	   //		    .font(.system(size: 18.0, weight: .bold, design: .rounded))
	   //		  DatePicker("", selection: $settingsViewModel.alarm, displayedComponents: .hourAndMinute)
	   //		    .font(.system(size: 20.0))
	   //		}
	   //	   }
	   //	   Section(header: Text("")) {
	   //		HStack {
	   //		  Text("Audio I/O")
	   //		    .font(.system(size: 18.0, weight: .bold, design: .rounded))
	   //		  Spacer()
	   //		  Image(systemName: "headphones.circle.fill")
	   //		    .font(.system(size: 32.0, weight: .bold, design: .rounded))
	   //		}
	   //		HStack {
	   //		  Text("Bluetooth")
	   //		    .font(.system(size: 18.0, weight: .bold, design: .rounded))
	   //		  Spacer()
	   //		  Image(systemName: "waveform.circle.fill")
	   //		    .font(.system(size: 32.0))
	   //		}
	   //		HStack {
	   //		  Text("AirPlay").font(.system(size: 14.0))
	   //		  Spacer()
	   //		  Image(systemName: "airplayaudio.circle.fill")
	   //		    .font(.system(size: 32.0))
	   //		}
	   //	   }
	   //	   Section(header: Text("")) {
	   //	   }.opacity(1)
	   //	 }
	   //
	   //	 .background(Color.clear.opacity(0.1))
	   
	   //    .navigationTitle("Settings")
	 }
	 .onAppear {
//	   self.character = character
	   self.characterSettingsViewModel = characterSettingsViewModel
	 }
    }
  }

  var body: some View {
//    let characterSettings = settingsViewModel.characterViewModel.characterSettings[settingsViewModel.characterViewModel.selectedCharacter]

    VStack (spacing: -15) {
	 // Header

	 settingsForm
    }
    .foregroundColor(.white)
    .colorScheme(.dark)
    .frame(width: 340, height: (UIScreen.main.bounds.height * 1) + 2)
    .background(Color.black.opacity(0.95))
    .cornerRadius(30)
    .overlay(
	 RoundedRectangle(cornerRadius: 30)
	   .strokeBorder(Color.black.opacity(0.85), lineWidth: 4)
    )
    .transition(.move(edge: .trailing))
    .animation(.easeInOut)
    .padding(.bottom, 1)
    .padding(.trailing, -5)
    .onAppear {
	 settingsViewModel.name = UserDefaults.standard.string(forKey: "name") ?? ""
	 settingsViewModel.age = UserDefaults.standard.string(forKey: "age") ?? ""
	 settingsViewModel.interests = UserDefaults.standard.string(forKey: "interests") ?? ""
	 settingsViewModel.topics = UserDefaults.standard.string(forKey: "topics") ?? ""
//	 settingsViewModel.updateBubbleColor(from: characterViewModel)
    }
    .onDisappear {
	 settingsViewModel.saveSettings(name: settingsViewModel.name, age: settingsViewModel.age, topics: settingsViewModel.topics, interests: settingsViewModel.interests, characterName: settingsViewModel.characterName, voiceIdentifier: settingsViewModel.voiceIdentifier, characterDescription: settingsViewModel.characterDescription, primaryColor: colorManager.primaryColor, secondaryColor: colorManager.secondaryColor)
    }

//    .onTapGesture {
//	 UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//    }
#if os(tvOS)
    .edgesIgnoringSafeArea(.all)
    .persistentSystemOverlays(.hidden)
#else
    .statusBar(hidden: true)
#endif
  }
}

//struct ActionSettingsView: View {
//  @ObservedObject var viewModel: ViewModel
//  @ObservedObject var characterViewModel: CharacterViewModel
//  @EnvironmentObject var settingsViewModel: SettingsViewModel
//  @ObservedObject var audioBufferPlayer = AudioBufferPlayer.shared
//
//  @State var speechSynthesizerHandler: SpeechSynthesizerHandler?
//
////  @ObservedObject var isLeftButtonToggled: SettingsViewModel
//  @State var isMuteButtonToggled: Bool = false
//  @State var isKeepButtonToggled: Bool = false
//  @State var isDeleteButtonToggled: Bool = false
//
//  @State private var isMuted: Bool = false
//
//
//
//  var body: some View {
//
//	   HStack {
//
//
//
//		Button(action: {
//		  isMuteButtonToggled.toggle()
//		  isMuted.toggle()
//		  AudioBufferPlayer.shared.muteUnmuteVolume(isMuted: isMuted)
//		}) {
//		  VStack {
//		    Image(systemName: isMuteButtonToggled ? "speaker.slash.circle" : "speaker.wave.2.circle")
//			 .foregroundColor(Color.white.opacity(0.65))
//			 .font(.system(size: 50.0, weight: .thin, design: .rounded))
//			 .rotationEffect(.degrees(isMuteButtonToggled ? 360 : 0))
////		    Spacer()
//		    Text(isMuteButtonToggled ? "Muted" : "Mute")
//			 .foregroundColor(Color.white.opacity(0.65))
//			 .font(.system(size: 14.0, weight: .heavy, design: .rounded))
//			 .lineLimit(1)
//		  }
//		  .padding(0)
//		}.disabled(true)
//		  .contentShape(Rectangle())
//		  .buttonStyle(PlainButtonStyle())
//		  .background(Color.black.opacity(0))
//		  .cornerRadius(15)
//		  .overlay(
//		    RoundedRectangle(cornerRadius: 15)
//			 .stroke(Color.clear, lineWidth: 0.5)
//		  )
//		  .foregroundColor(.white)
//		  .allowsHitTesting(true)
//		Spacer()
//		  .frame(width: 20)
//
//
//
//		Button(action: {
//		  settingsViewModel.isLeftButtonToggled.toggle()
//
//		}) {
//		  VStack {
//		    Image(systemName: settingsViewModel.isLeftButtonToggled ? "hand.raised.circle" : "hand.raised.circle")
//			 .foregroundColor(Color.white.opacity(0.65))
//			 .font(.system(size: 50.0, weight: .thin, design: .rounded))
//			 .scaleEffect(x: (settingsViewModel.isLeftButtonToggled ? -1 : 1), y: 1, anchor: .center)
////		    Spacer().frame(height: 5)
//		    Text(settingsViewModel.isLeftButtonToggled ? "Left" : "Right")
//			 .foregroundColor(Color.white.opacity(0.65))
//			 .font(.system(size: 14.0, weight: .heavy, design: .rounded))
//			 .lineLimit(1)
//
//		  }
//		  .padding(0)
//		}
//		.contentShape(Rectangle())
//		.buttonStyle(PlainButtonStyle())
//		.background(Color.black.opacity(0))
////		.background(RoundedRectangle(cornerRadius: 15).fill(buttonColors(for: characterViewModel.characters[index])?.secondary ?? Color.clear).opacity(0.3))
//		.cornerRadius(15)
//		.overlay(
//		  RoundedRectangle(cornerRadius: 15)
//		    .stroke(Color.clear, lineWidth: 0.5)
//		)
//		.foregroundColor(.white)
//		.allowsHitTesting(true)
//		Spacer()
//		  .frame(width: 20)
//
//
//
//		Button(action: {
//		  isKeepButtonToggled.toggle()
//		  settingsViewModel.settingsState.isPreserveMessagesEnabled = isKeepButtonToggled
//		}) {
//		  VStack {
//		    Image(systemName: isKeepButtonToggled ? "hand.thumbsup.circle" : "hand.thumbsup.circle")
//			 .foregroundColor(Color.white.opacity(0.65))
//			 .font(.system(size: 50.0, weight: .thin, design: .rounded))
//			 .scaleEffect(x: 1, y: (isKeepButtonToggled ? -1 : 1), anchor: .center)
////		    Spacer().frame(height: 5)
//		    Text(isKeepButtonToggled ? "Forget" : "Store")
//			 .foregroundColor(Color.white.opacity(0.65))
//			 .font(.system(size: 14.0, weight: .heavy, design: .rounded))
//			 .lineLimit(1)
//		  }
//		  .padding(0)
//		}.disabled(true)
//		  .contentShape(Rectangle())
//		  .buttonStyle(PlainButtonStyle())
//		  .background(Color.black.opacity(0))
//		  .cornerRadius(15)
//		  .overlay(
//		    RoundedRectangle(cornerRadius: 15)
//			 .stroke(Color.clear, lineWidth: 0.5)
//		  )
//		  .foregroundColor(.white)
//		  .allowsHitTesting(true)
//		Spacer()
//		  .frame(width: 20)
//
//
//
//		Button(action: {
//		  withAnimation(.easeInOut(duration: 0.5)) {
//		    isDeleteButtonToggled.toggle()
//		  }
//		  DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
//		    withAnimation(.easeInOut(duration: 0.5)) {
//			 isDeleteButtonToggled.toggle()
//		    }
//		  }
//		  viewModel.cancelStreamingResponse()
//		  viewModel.clearMessages()
//		  audioBufferPlayer.stopSpeaking()
//
//		}) {
//		  VStack {
//		    Image(systemName: isDeleteButtonToggled ? "trash.circle" : "trash.circle")
//			 .foregroundColor(Color.white.opacity(0.65))
//			 .font(.system(size: 50.0, weight: .thin, design: .rounded))
//			 .rotationEffect(.degrees(isDeleteButtonToggled ? 180 : 0))
////		    Spacer().frame(height: 5)
//		    Text("Delete")
//			 .foregroundColor(Color.white.opacity(0.65))
//			 .font(.system(size: 14.0, weight: .heavy, design: .rounded))
//			 .lineLimit(1)
//		  }
//		  .padding(0)
//		}
//		.contentShape(Rectangle())
//		.buttonStyle(PlainButtonStyle())
//		.background(Color.black.opacity(0))
//		.cornerRadius(15)
//		.overlay(
//		  RoundedRectangle(cornerRadius: 15)
//		    .stroke(Color.clear, lineWidth: 0.5)
//		)
//		.foregroundColor(.white)
//		.allowsHitTesting(true)
//	   }
//	   .onAppear {
//		self.speechSynthesizerHandler = SpeechSynthesizerHandler(viewModel: viewModel, audioBufferPlayer: audioBufferPlayer)
//	   }
//	 VStack {
//	   HStack {
//		Text("Preserve Chat")
//		  .font(.system(size: 16.0))
//		  .background(Color.black.opacity(0))
//		Spacer()
//		Toggle("", isOn: $settingsViewModel.settingsState.isPreserveMessagesEnabled)
//		  .onChange(of: settingsViewModel.settingsState.isPreserveMessagesEnabled) { value in
//		    settingsViewModel.settingsState.isPreserveMessagesEnabled = value
//		  }
//	   }
//	   .background(Color.black.opacity(0))
//	 }
//	 .background(Color.black.opacity(0))
//  }
//
//
//}

struct UserSettingsView: View {
  @ObservedObject var settingsViewModel: SettingsViewModel
  @ObservedObject var characterViewModel: CharacterViewModel
  @State var remoteControl: RemoteControl
  @Binding var availableVoices: [String]

  var body: some View {
    VStack {
	 HStack {
	   VStack (alignment: .leading, spacing: 4){
		Text("The Person")
		  .foregroundColor(Color.white.opacity(0.65))
		  .font(.system(size: 12.0, weight: .bold, design: .rounded))
		  .padding(.leading, 5)
		TextField("", text: $settingsViewModel.name)
		  .font(.system(size: 16.0, weight: .black, design: .rounded))
		  .multilineTextAlignment(.leading)
		  .textFieldStyle(.roundedBorder)
		  .background(Color.black)
		  .mask(RoundedRectangle(cornerRadius: 10))
		  .opacity(0.65)
		  .foregroundColor(Color.white.opacity(1))
	   }.padding(.trailing, 2)
	   VStack (alignment: .leading, spacing: 4){
		Text("Age")
		  .foregroundColor(Color.white.opacity(0.65))
		  .font(.system(size: 12.0, weight: .bold, design: .rounded))
		  .padding(.leading, 5)
		TextField("", text: $settingsViewModel.age)
		  .font(.system(size: 16.0, weight: .black, design: .rounded))
		  .multilineTextAlignment(.leading)
		  .keyboardType(.numberPad)
		  .textFieldStyle(.roundedBorder)
		  .background(Color.black)
		  .mask(RoundedRectangle(cornerRadius: 10))
		  .opacity(0.65)
		  .foregroundColor(Color.white.opacity(1))
	   }.frame(width: 50)
	 }.padding(.horizontal, -12)
	 Spacer()
	   .frame(height: 12)
	 //	 HStack {
	 //	   Text("Language")
	 //		.font(.system(size: 16.0, weight: .bold, design: .rounded))
	 //	   Spacer()
	 //	   Picker("", selection: $settingsViewModel.voiceIdentifier) {
	 //		ForEach(availableVoices, id: \.self) { voice in
	 //		  Text("English")
	 //		    .font(.system(size: 16.0, weight: .regular, design: .rounded))
	 //		    .foregroundColor(.gray)
	 //		}
	 //	   }
	 //	 }


	 VStack (alignment: .leading, spacing: 4){
	   Text("Communication Style")
		.foregroundColor(Color.white.opacity(0.65))
		.font(.system(size: 12.0, weight: .bold, design: .rounded))
		.padding(.leading, 5)
	   TextField("", text: $settingsViewModel.interests)
		.font(.system(size: 16.0, weight: .black, design: .rounded))
	   //		.multilineTextAlignment(.trailing)
		.textFieldStyle(.roundedBorder)
		.background(Color.black)
		.mask(RoundedRectangle(cornerRadius: 10))
		.opacity(0.65)
		.foregroundColor(Color.white.opacity(1))
	 }.padding(.horizontal, -12)
	 Spacer()
	   .frame(height: 12)



	 VStack (alignment: .leading, spacing: 4){
	   Text("Topics & Interests")
		.foregroundColor(Color.white.opacity(0.65))
		.font(.system(size: 12.0, weight: .bold, design: .rounded))
		.padding(.leading, 5)
	   TextEditor(text: $settingsViewModel.topics)
		.frame(height: 80)
		.foregroundColor(Color.white.opacity(0.65))
		.scrollContentBackground(.hidden) // <- Hide it
		.lineSpacing(3)
		.padding(3)
		.background(Color.black.opacity(0.95).mask(RoundedRectangle(cornerRadius: 10, style: .circular)))
		.font(.system(size: 12.0, weight: .black, design: .rounded))
//		.padding(.horizontal, -5)
//		.padding(.vertical, -5)
		.overlay(
		  RoundedRectangle(cornerRadius: 5)
		    .stroke(Color.white.opacity(0), lineWidth: 0.5)
		)
	 }.padding(.horizontal, -12)

	 Spacer()
	   .frame(height: 12)


	 HStack {
	   VStack {
		Text("Hand")
		  .foregroundColor(Color.white.opacity(0.65))
		  .font(.system(size: 12.0, weight: .bold, design: .rounded))
		  .padding(.bottom, -5)
		  .padding(.leading, -19)

		Button(action: {
		  settingsViewModel.isLeftButtonToggled.toggle()
		  
		}) {
		  VStack {
		    Image(systemName: settingsViewModel.isLeftButtonToggled ? "hand.raised.circle" : "hand.raised.circle")
			 .foregroundColor(Color.white.opacity(0.65))
			 .font(.system(size: 35.0, weight: .thin, design: .rounded))
			 .scaleEffect(x: (settingsViewModel.isLeftButtonToggled ? -1 : 1), y: 1, anchor: .center)
		    //		    Spacer().frame(height: 5)
		    Text(settingsViewModel.isLeftButtonToggled ? "Left" : "Right")
			 .foregroundColor(Color.white.opacity(0.65))
			 .font(.system(size: 14.0, weight: .heavy, design: .rounded))
			 .lineLimit(1)
		  }.padding(10)
		}
		.contentShape(Rectangle())
		.buttonStyle(PlainButtonStyle())
		.background(Color.black.opacity(1))
		//		.background(RoundedRectangle(cornerRadius: 15).fill(buttonColors(for: characterViewModel.characters[index])?.secondary ?? Color.clear).opacity(0.3))
		.cornerRadius(10)
		.foregroundColor(.white)
		.allowsHitTesting(true)
	   }
	   Spacer()
	 }.padding(.horizontal, -12)


	 HStack {
	   VStack {
		Text("Remote")
		  .foregroundColor(Color.white.opacity(0.65))
		  .font(.system(size: 12.0, weight: .bold, design: .rounded))
		  .padding(.bottom, -5)
		  .padding(.leading, -19)

		Button(action: {
		  settingsViewModel.isRecordMode.toggle()
		  remoteControl.updateRemoteControlCommands()


		}) {
		  VStack {
		    Image(systemName: settingsViewModel.isRecordMode ? "playpause.circle" : "recordingtape.circle")
			 .foregroundColor(Color.white.opacity(0.65))
			 .font(.system(size: 35.0, weight: .thin, design: .rounded))
			 .scaleEffect(x: (settingsViewModel.isRecordMode ? -1 : 1), y: 1, anchor: .center)
		    //		    Spacer().frame(height: 5)
		    Text(settingsViewModel.isRecordMode ? "Left" : "Right")
			 .foregroundColor(Color.white.opacity(0.65))
			 .font(.system(size: 14.0, weight: .heavy, design: .rounded))
			 .lineLimit(1)
		  }.padding(10)
		}
		.contentShape(Rectangle())
		.buttonStyle(PlainButtonStyle())
		.background(Color.black.opacity(1))
		//		.background(RoundedRectangle(cornerRadius: 15).fill(buttonColors(for: characterViewModel.characters[index])?.secondary ?? Color.clear).opacity(0.3))
		.cornerRadius(10)
		.foregroundColor(.white)
		.allowsHitTesting(true)
	   }
	   Spacer()
	 }.padding(.horizontal, -12)

    }
    .padding(.horizontal, 25)
    .padding(.vertical, 15)
    .background(characterViewModel.colorManager.secondaryColor).opacity(1)
//    .blendMode(.multiply)
//    .background(.white.opacity(0.02))
    .cornerRadius(15) /// make the background rounded
    .overlay( /// apply a rounded border
	 RoundedRectangle(cornerRadius: 10)
	   .stroke(Color.white.opacity(0), lineWidth: 0.5)
    )

  }
}

//
//struct SettingsView_Previews: PreviewProvider {
//  static var previews: some View {
//
//    let talkieBio = "You are Talkie....."
//    let talkieRapport = "You like discussing complex topics...."
//    let talkieFormat = "Sometimes address the person you are chatting with by their name...."
//    let character = Character(id: "Talkie", name: "Talkie", voiceIdentifier: "com.apple.voice.premium.en-IN.Isha", bgColor: CharacterColor(primary: Color("TalkiePrimary"), secondary: Color("TalkieSecondary")), description: "You are Talkie the Robot from the internet....", bio: talkieBio, rapport: talkieRapport, format: talkieFormat)
//
//    SettingsView(
//	 isPresented: .constant(true),
//	 characterViewModel: CharacterViewModel(userSettings: CharacterViewModel.sharedUserSettings),
//	 selectedCharacter: .constant(Character(id: "Talkie", name: "Talkie", voiceIdentifier: "com.apple.voice.premium.en-IN.Isha", bgColor: CharacterColor(primary: Color("TalkiePrimary"), secondary: Color("TalkieSecondary")), description:
//									 "You are Talkie the Robot from the internet.... \(talkieRapport) \(talkieFormat) (Nickname: Talkie the GPT Robot)", bio: talkieBio, rapport: talkieRapport, format: talkieFormat)),
////	 bubbleColor: .red,
//	 viewModel: ViewModel(api: ChatGPTAPI(character: character), selectedCharacterId: "0", bio: character.bio, rapport: character.rapport, format: character.format)
//    )
//  }
//}
