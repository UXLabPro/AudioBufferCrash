//
//  ToolbarView.swift
//  Talkie
//
//  Created by Clif on 02/04/2023.
//

import SwiftUI
import Foundation
import Combine

class ToolbarSettings: ObservableObject {
  @Published var isPresentingSettings: Bool = false
  @Published var showingDropdown: Bool = false
}


struct ToolbarView: View {

  @EnvironmentObject var appIntent: AppIntent // Access appIntent from the environment
  @EnvironmentObject var toolbarSettings: ToolbarSettings

//  @Binding var showingDropdown: Bool


  @ObservedObject var characterViewModel: CharacterViewModel
  @ObservedObject var vm: ViewModel
  @ObservedObject var settingsViewModel: SettingsViewModel
  @ObservedObject var characterSettingsViewModel: CharacterSettingsViewModel
  @ObservedObject var colorManager: ColorManager

  @ObservedObject var audioBufferPlayer = AudioBufferPlayer.shared

  @State private var isPaused: Bool = false

  var onStopSpeech: () -> Void // Add this
  var onStartSpeech: () -> Void // Add this

  @Binding var selectedCharacter: Character?
  var onUpdateSelectedCharacter: () -> Void

  @State var character: Character?


  @Binding var shouldAnimate: Bool // Add this variable

  @State var isMuteButtonToggled: Bool = false
  @State var isKeepButtonToggled: Bool = false
  @State var isDeleteButtonToggled: Bool = false

  @State private var isMuted: Bool = false


//  @Binding var isLeftButtonToggled: Bool

  private var selectedIndex: Int? {
    guard let character = selectedCharacter else { return nil }
    return characterViewModel.characters.firstIndex(where: { $0.id == character.id })
  }

  init(
//    showingDropdown: Binding<Bool>,
	  characterViewModel: CharacterViewModel,
	  vm: ViewModel,
	  settingsViewModel: SettingsViewModel,
	  characterSettingsViewModel: CharacterSettingsViewModel,
	  colorManager: ColorManager,
//	  audioBufferPlayer: AudioBufferPlayer,
	  selectedCharacter: Binding<Character?>,
	  shouldAnimate: Binding<Bool>,
	  onStopSpeech: @escaping () -> Void,
	  onStartSpeech: @escaping () -> Void,
//	  isLeftButtonToggled: Binding<Bool>,
	  onUpdateSelectedCharacter: @escaping () -> Void) {
//    self._showingDropdown = showingDropdown
    self.characterViewModel = characterViewModel
    self.vm = vm
    self.settingsViewModel = settingsViewModel
    self.characterSettingsViewModel = characterSettingsViewModel
	    self.colorManager = colorManager
//    self.audioBufferPlayer = audioBufferPlayer
    self._selectedCharacter = selectedCharacter
    self._shouldAnimate = shouldAnimate
    self.onStopSpeech = onStopSpeech
    self.onStartSpeech = onStartSpeech
    self.onUpdateSelectedCharacter = onUpdateSelectedCharacter
//    self._isLeftButtonToggled = isLeftButtonToggled
  }

  var body: some View {
    ZStack {
	 HStack {
	   Button(action: {
		withAnimation(shouldAnimate ? .easeInOut(duration: 1.3) : .none) { // Use shouldAnimate variable to control animation
		  toolbarSettings.showingDropdown.toggle()
		}
	   }) {
		HStack {
		  if let character = selectedCharacter, let _ = selectedIndex  {
		    VStack {
			 Image("character")
			   .resizable()
			   .frame(width: 55, height: 55)
			   .aspectRatio(contentMode: .fit)
			   .background(Color.clear)
			   .tint(characterViewModel.safeSecondaryColorAsColor(at: characterViewModel.selectedCharacterIndex))
			 //			 .background(Circle().fill(.white).frame(width: 30, height: 30))
			 

		    }
		    VStack {
			 
			 Spacer()
			   .frame(height: 14)
			 if let character = selectedCharacter, characterViewModel.characters.firstIndex(of: character) ?? 0 < 2 {
			   Text(character.name)
				.font(.system(size: 22.0, weight: .black, design: .rounded))
				.lineLimit(1)
			   
			 } else {
			   Text(character.name + "")
				.font(.system(size: 22.0, weight: .black, design: .rounded))
				.lineLimit(1)
			   
			   //			   Spacer()
			   //				.frame(height: 2)
			   
			 }
		    }
		  }
		}
		.padding(.leading, 10)
		.padding(.top, 15)
		.foregroundColor(.white)
		//	   .background(Color.clear)
	   }
	   //	   .opacity(toolbarSettings.showingDropdown ? 0 : 0.95)
	   //	   .opacity(toolbarSettings.isPresentingSettings ? 0 : 0.95)
	   //	   .animation(.easeOut(duration: 0.4))
	   Spacer()
	   
	   VStack {
		HStack {
		  
		  Button(action: {
		    withAnimation(.easeInOut(duration: 0.5)) {
			 isDeleteButtonToggled.toggle()
		    }
		    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
			 withAnimation(.easeInOut(duration: 0.5)) {
			   isDeleteButtonToggled.toggle()
			 }
		    }
		    vm.cancelStreamingResponse()
		    vm.clearMessages()
		    audioBufferPlayer.stopSpeaking()
		    
		  }) {
		    Image(systemName: isDeleteButtonToggled ? "trash.circle" : "trash.circle")
			 .foregroundColor(Color.white.opacity(0.65))
			 .font(.system(size: 35.0, weight: .thin, design: .rounded))
			 .rotationEffect(.degrees(isDeleteButtonToggled ? -180 : 0))
		  }
		  .buttonStyle(PlainButtonStyle())
		  .allowsHitTesting(true)
		  .padding(.trailing, -1)

		  
		  
		  
		  Button(action: {
		    toolbarSettings.isPresentingSettings.toggle()
		  }) {
		    Image(systemName: "person.circle")
			 .font(.system(size: 35.0, weight: .thin, design: .rounded))
			 .foregroundColor(Color.white.opacity(0.65))
			 .animation(.easeOut(duration: 0.4))
		  }.onChange(of: toolbarSettings.isPresentingSettings) { _ in
		    withAnimation(shouldAnimate ? .easeInOut(duration: 1.3) : .none) {
		    }
		  }
		  
		}.padding(.bottom, 1)

		HStack {

		  
		  
		  Button(action: {
		    vm.cancelStreamingResponse()
		    audioBufferPlayer.stopSpeaking()
		  }) {
		    Image(systemName: "stop.circle")
			 .font(.system(size: 35.0, weight: .thin, design: .rounded))
			 .foregroundColor(Color.white.opacity(0.65))
		  }
		  .buttonStyle(PlainButtonStyle())
		  .allowsHitTesting(true)
		  .padding(.trailing, -1)



	   Button(action: {
		appIntent.isPlaying.toggle()
		if !self.appIntent.isPlaying {
		  self.appIntent.pause()
		} else if self.appIntent.isPlaying {
		  self.appIntent.resume()
		}
	   }) {
		Image(systemName: appIntent.isPlaying ? "pause.circle" : "play.circle")
		  .font(.system(size: 35.0, weight: .thin, design: .rounded))
		  .foregroundColor(Color.white.opacity(0.65))
		  .rotationEffect(.degrees(appIntent.isPlaying ? 360 : 0))
		  .animation(.easeOut(duration: 0.4))
	   }
	   .buttonStyle(PlainButtonStyle())
	   .allowsHitTesting(true)
	   //	   .foregroundColor(characterViewModel.characters.first(where: { $0.id == (selectedCharacter?.id ?? "") })?.bgColor.secondary ?? .white).opacity(0.95)
	   //	   .disabled(vm.isInteractingWithChatGPT)




		}
	   }.padding(.trailing, 20)
		.padding(.top, 0)
    }






//	 if toolbarSettings.isPresentingSettings || toolbarSettings.showingDropdown {
//	   Color.clear
//		.contentShape(Rectangle())
//		.onTapGesture {
//		  withAnimation {
//		    toolbarSettings.isPresentingSettings = false
//		    toolbarSettings.showingDropdown = false
//		  }
//		}
//	 }

	 if toolbarSettings.isPresentingSettings {
//	   GeometryReader { geometry in
	   SettingsView(
		viewModel: vm,
		isPresented: $toolbarSettings.isPresentingSettings,
		characterViewModel: characterViewModel,
		settingsViewModel: settingsViewModel,
		selectedCharacter: $selectedCharacter,
		character: character ?? Character(id: "", name: "", voiceIdentifier: "", bgColor: CharacterColor(primary: Color.white, secondary: Color.white), description: "", bio: "", rapport: "", format: ""),
		characterSettingsViewModel: characterSettingsViewModel,
		colorManager: colorManager
	   )
	   .environmentObject(settingsViewModel)
	   .environmentObject(characterSettingsViewModel)
	   .frame(alignment: .trailing)
		.background(Color.black.opacity(0))
		.transition(.move(edge: .trailing))
		.animation(.easeInOut(duration: 0.3))
		.alignToBottomToolbar()
//	   }
	 }
	 //    .fullScreenCover(isPresented: $isPresentingSettings) {
	 //	 SettingsView(
	 //	   isPresented: $isPresentingSettings,
	 //	   characterViewModel: characterViewModel,
	 //	   selectedCharacter: $selectedCharacter,
	 ////	   bubbleColor: Color.red, // replace with your chosen default color
	 //	   viewModel: vm
	 //	 )
	 //
	 //	 .background(Color.black.opacity(0.1))
    }

    .onAppear {
	 if let selectedCharacter = selectedCharacter {
	   character = selectedCharacter
	 }

    }
    .onChange(of: selectedCharacter) { newValue in
	 character = newValue
    }

//    .onAppear {
//	 print("ToolbarView - selectedCharacter: \(String(describing: selectedCharacter))")
//    }
    .padding(.trailing, 4)
    .padding(.leading, 16)
//    .padding(.bottom, -60)
    .frame(height: 40)
    .background(Color.clear)
    .onChange(of: selectedCharacter) { newValue in
	 if let character = newValue, let index = characterViewModel.characters.firstIndex(where: { $0.id == character.id }) {
	   // Update the color when the selected character changes
	   characterViewModel.selectedCharacterIndex = index
	 }
    }
  }
}

struct BackgroundClearView: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    DispatchQueue.main.async {
	 view.superview?.superview?.backgroundColor = .clear
    }
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {}
}

extension AnyTransition {
  static var moveAndFade: AnyTransition {
    let insertion = AnyTransition.move(edge: .trailing)
	 .combined(with: .opacity)
    let removal = AnyTransition.move(edge: .trailing)
	 .combined(with: .opacity)
    return .asymmetric(insertion: insertion, removal: removal)
  }
}

extension View {
  func alignToBottomToolbar() -> some View {
    self
	 .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
	 .position(x: UIScreen.main.bounds.width / 2, y: (UIScreen.main.bounds.height / 2) - 16)
  }
}

