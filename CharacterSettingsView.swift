//
//  CharacterSettingsView.swift
//  Talkie
//
//  Created by Clif on 12/06/2023.
//

import SwiftUI
import PhotosUI


struct CharacterSettingsView: View {
  @ObservedObject var viewModel: ViewModel
  @ObservedObject var characterViewModel: CharacterViewModel
  @ObservedObject var settingsViewModel: SettingsViewModel
  @ObservedObject var characterSettingsViewModel: CharacterSettingsViewModel
  @ObservedObject var colorManager: ColorManager
  @Binding var isPresented: Bool
  @Binding var availableVoices: [String]
  @ObservedObject var audioBufferPlayer = AudioBufferPlayer.shared
  @Binding var selectedCharacter: Character?
  @ObservedObject var photosModel: PhotoPickerModel
  @State private var selectedItem: PhotosPickerItem? = nil
  @State private var selectedImageData: Data? = nil
  @State private var isPhotoPickerPresented = false

  private var selectedIndex: Int? {
    guard let character = selectedCharacter else { return nil }
    return characterSettingsViewModel.characterViewModel.characters.firstIndex(where: { $0.id == character.id })
  }

  init(
    isPresented: Binding<Bool>,
    characterViewModel: CharacterViewModel,
    selectedCharacter: Binding<Character?>,
    viewModel: ViewModel,
    availableVoices: Binding<[String]>,
    settingsViewModel: SettingsViewModel,
    colorManager: ColorManager
  ) {
    self.settingsViewModel = settingsViewModel
    self.characterViewModel = characterViewModel
    self.viewModel = viewModel
    self.colorManager = colorManager
    self._isPresented = isPresented
    self._selectedCharacter = selectedCharacter
    self._availableVoices = availableVoices
    self.photosModel = PhotoPickerModel()

    // Create an instance of CharacterSettingsViewModel
    if let character = selectedCharacter.wrappedValue {
	 self.characterSettingsViewModel = CharacterSettingsViewModel(characterViewModel: CharacterViewModel.shared, character: character)
    } else {
	 // Handle the case where selectedCharacter is nil
	 // You can create a default Character instance or handle this case differently
	 let defaultCharacter = Character(id: "", name: "", voiceIdentifier: "", bgColor: CharacterColor(primary: Color.white, secondary: Color.white), description: "", bio: "", rapport: "", format: "")
	 self.characterSettingsViewModel = CharacterSettingsViewModel(characterViewModel: CharacterViewModel.shared, character: defaultCharacter)
    }


    let primaryColor: Color = CharacterViewModel.shared.getColor(characterId: characterViewModel.selectedCharacter?.id).0
    let secondaryColor: Color = CharacterViewModel.shared.getColor(characterId: characterViewModel.selectedCharacter?.id).1
    //     self.settingsState = settingsViewModel.settingsState
    //     self._isClearMessagesEnabled = State(initialValue: settingsState.isClearMessagesEnabled) // Initialize the property here
    self.audioBufferPlayer = audioBufferPlayer
  }


  var primaryColor: Color {
    characterSettingsViewModel.primaryColor
  }

  var secondaryColor: Color {
    characterSettingsViewModel.secondaryColor
  }

  var primaryBackgroundColor: Color {
    if let uiColor = characterViewModel.selectedCharacter?.bgColor.primaryUIColor {
	 return Color(uiColor).opacity(0.8)
    } else {
	 return Color.red
    }
  }

  var body: some View {
    VStack {
	 VStack (alignment: .leading, spacing: 4){
	   Text("The Robot")
		.foregroundColor(Color.white.opacity(0.65))
		.font(.system(size: 12.0, weight: .bold, design: .rounded))
		.padding(.leading, 5)
	   TextField("", text: Binding<String>(
		get: { self.characterSettingsViewModel.characterName },
		set: { self.characterSettingsViewModel.characterName = $0 }
	   ))
	   .font(.system(size: 14.0, weight: .black, design: .rounded))
	   .background(Color.black)
	   .mask(RoundedRectangle(cornerRadius: 10))
	   .opacity(0.65)
	   .foregroundColor(Color.white.opacity(1))
	   .multilineTextAlignment(.leading)
	   .textFieldStyle(.roundedBorder)
	   .keyboardType(.default)
	 }.padding(.horizontal, -12)
	   .padding(.top, -10)
	   .onChange(of: selectedCharacter) { newValue in
		if let character = newValue, let index = characterViewModel.characters.firstIndex(where: { $0.id == character.id }) {
		  // Update the color when the selected character changes
		  characterViewModel.selectedCharacterIndex = index
		  // Update the character of CharacterSettingsViewModel
		  characterSettingsViewModel.character = character
		}
	   }
	 Spacer().frame(height: 15)

//	 HStack {
//	   VStack (alignment: .leading, spacing: 0){
//		Text("Voice")
//		  .foregroundColor(Color.white.opacity(0.65))
//		  .font(.system(size: 12.0, weight: .ultraLight, design: .rounded))
//		  .padding(.bottom, 15)
//		  .padding(.leading, 12)
//		Group {
//		  Picker("", selection: $characterSettingsViewModel.voiceIdentifier) {
//		    ForEach(availableVoices, id: \.self) { voice in
//			 Text(voice.split(separator: ".").last ?? "").tag(voice)
//			   .font(.system(size: 14.0, weight: .black, design: .rounded))
//		    }
//		  }.frame(width: 130, height: 33)
//		    .padding(.bottom, 27)
//		    .padding(.leading, 0)
//		  //		  .background(Color.black)
//		    .tint(Color.white.opacity(0.65))
//		}.frame(width: 110, height: 33)
//		  .padding(.leading, 25)
//
//		//	   .padding(.trailing, -13)
//	   }
//	   .padding(.leading, -14)
//	   .frame(width: 110, height: 33)
//	   .background(Color.black)
//	   .overlay( /// apply a rounded border
//		RoundedRectangle(cornerRadius: 5)
//		  .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
//		  .padding(.leading, -12)
//	   )
//	   Spacer().frame(width: 10)
//
//	   VStack(alignment: .leading, spacing: 0) {
//		Text("Imagery")
//		  .foregroundColor(Color.white.opacity(0.65))
//		  .font(.system(size: 12.0, weight: .ultraLight, design: .rounded))
//		  .padding(.bottom, 4)
//		  .padding(.leading, 13)
//		HStack (alignment: .center, spacing: 4) {
//		  Spacer()
//		  ForEach(0..<4) { index in // to display 4 image views
//		    if index < photosModel.loadedImages.count {
//			 photosModel.loadedImages[index].image
//			   .resizable()
//			   .scaledToFit()
//			   .frame(width: 25, height: 25)
//			   .onTapGesture {
//				photosModel.currentIndex = index
//				isPhotoPickerPresented = true
//			   }
//		    } else {
//			 Image(systemName: "photo") // placeholder image
//			   .resizable()
//			   .scaledToFit()
//			   .frame(width: 25, height: 25)
//			   .onTapGesture {
//				photosModel.currentIndex = index
//				isPhotoPickerPresented = true
//			   }
//			   .highPriorityGesture(TapGesture())
//		    }
//		  }
//		  Spacer()
//		}.padding(.bottom, 4)
//		  .background(Color.black)
//		//	   .padding(.trailing, -20)
//		//	 .sheet(isPresented: $isPhotoPickerPresented) {
//		PhotosPicker(
//		  selection: $photosModel.selectedPhoto,
//		  matching: .any(of: [.images]),
//		  photoLibrary: .shared()) {
//		    Text("")
//		  }
//		  .onChange(of: selectedItem) { newItem in
//		    Task {
//			 if let data = try? await newItem?.loadTransferable(type: Data.self) {
//			   selectedImageData = data
//			 }
//		    }
//		  }
//		//	 }
//		if let selectedImageData,
//		   let uiImage = UIImage(data: selectedImageData) {
//		  Image(uiImage: uiImage)
//		    .resizable()
//		    .scaledToFit()
//		    .frame(width: 250, height: 250)
//		}
//		//		    .overlay {
//		//			 PhotosPicker(selection: $photosModel.selectedPhoto, matching: .any(of: [.images]), photoLibrary: .shared()) {
//		//			   Image(systemName: "photo.fill")
//		//				.font(.callout)
//		//			 }
//		//		    }
//	   }.frame(width: 120, height: 33)
//		.background(Color.black)
//		.overlay( /// apply a rounded border
//		  RoundedRectangle(cornerRadius: 5)
//		    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
//		)
//	   //		  if !photosModel.loadedImages.isEmpty {
//	   //		    photosModel.loadedImages[photosModel.currentIndex].image
//	   //			 .resizable()
//	   //			 .aspectRatio(contentMode: .fit)
//	   //			 .padding()
//	   //		  }
//	 }
//	 Spacer().frame(height: 20)

	 VStack (alignment: .leading, spacing: 4){
	   Text("Description & Backstory")
		.foregroundColor(Color.white.opacity(0.65))
		.font(.system(size: 12.0, weight: .bold, design: .rounded))
		.padding(.leading, 5)
		.padding(.bottom, 2)
	   TextEditor(text: $characterSettingsViewModel.characterDescription)
		.frame(height: 300)
		.foregroundColor(Color.white.opacity(0.65))
		.scrollContentBackground(.hidden) // <- Hide it
		.lineSpacing(3)
		.padding(3)
		.background(Color.black.opacity(0.95).mask(RoundedRectangle(cornerRadius: 10, style: .circular)))
		.font(.system(size: 12.0, weight: .black, design: .rounded))
		.overlay(
		  RoundedRectangle(cornerRadius: 10)
		    .stroke(Color.white.opacity(0), lineWidth: 0.5)

		)
	 }.padding(.horizontal, -12)
	 //	   .padding(.bottom, -10)
	 //    HStack {
	 //	 VStack {
	 //	   Slider(value: $audioBufferPlayer.rate, in: 0...1, step: 0.1)
	 //		.frame(width: 100)
	 //		.tint(Color.yellow)
	 //	   Text("Speed: \(audioBufferPlayer.rate)")
	 //		.font(.system(size: 18.0, weight: .bold, design: .rounded))
	 //		.frame(width: 100)
	 //		.padding(.top, -5)
	 //	 }
	 //	 VStack {
	 //	   Slider(value: $audioBufferPlayer.pitch, in: 0.5...2, step: 0.1)
	 //		.frame(width: 100)
	 //		.tint(Color.yellow)
	 //	   Text("Pitch: \(audioBufferPlayer.pitch)")
	 //		.font(.system(size: 18.0, weight: .bold, design: .rounded))
	 //		.frame(width: 100)
	 //		.padding(.top, -5)
	 //	 }
	 //	 VStack {
	 //	   Slider(value: $audioBufferPlayer.volume, in: 0...1, step: 0.1)
	 //		.frame(width: 100)
	 //		.tint(Color.yellow)
	 //	   Text("Volume: \(audioBufferPlayer.volume)")
	 //		.font(.system(size: 18.0, weight: .bold, design: .rounded))
	 //		.frame(width: 100)
	 //		.padding(.top, -5)
	 //	 }
	 //    }
	 //	 .padding(.horizontal, 0)
	 //	 .padding(.bottom, 0)

	 Spacer().frame(height: 25)

	 HStack {
	   CharacterColorPickerView(colorManager: ColorManager.shared, title: "Incoming", isPrimaryColor: true)
	   Spacer()
		.frame(width: 40)
	   CharacterColorPickerView(colorManager: ColorManager.shared, title: "Outgoing", isPrimaryColor: false)
	 }.padding(.leading, -7)
    }
    .padding(25)
    .background(colorManager.primaryColor)
    .cornerRadius(15)
    .overlay(
	 RoundedRectangle(cornerRadius: 15)
	   .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
    )
    .onChange(of: selectedCharacter) { newValue in
	 if let character = newValue,
	    let index = characterSettingsViewModel.characterViewModel.characters.firstIndex(where: { $0.id == character.id }) {
	   characterSettingsViewModel.characterViewModel.selectedCharacterIndex = index
	   characterSettingsViewModel.characterViewModel.selectedCharacter = character
	   characterSettingsViewModel.changeCharacterColors(character: character, primary: character.bgColor.primary, secondary: character.bgColor.secondary)
	 }
    }
  }
}



struct CharacterColorPickerView: View {
  @ObservedObject var colorManager: ColorManager
  var title: String
  var isPrimaryColor: Bool
  @State private var primaryColor: Color
  @State private var secondaryColor: Color

  init(colorManager: ColorManager, title: String, isPrimaryColor: Bool) {
    self.colorManager = colorManager
    self.title = title
    self.isPrimaryColor = isPrimaryColor
    self._primaryColor = State(initialValue: colorManager.primaryColor)
    self._secondaryColor = State(initialValue: colorManager.secondaryColor)
  }

  var body: some View {
    VStack {
	 HStack {
	   Text(title)
		.foregroundColor(Color.white.opacity(0.65))
		.font(.system(size: 12.0, weight: .bold, design: .rounded))
		.frame(maxWidth: .infinity, alignment: .leading)
		.allowsTightening(true)
		.lineLimit(1)
		.minimumScaleFactor(1)
		.padding(.trailing, -40)
	   HStack {
		ColorPicker(selection: isPrimaryColor ? $primaryColor : $secondaryColor, label: {
//		  Text("\(isPrimaryColor ? colorManager.primaryColorName : colorManager.secondaryColorName)")
//		    .font(.system(size: 14.0))
		})
		.padding(.leading, -10)
	   }
	 }
    }
  }
}


//
//#Preview {
//  CharacterSettingsView(settingsViewModel: settingsViewModel, availableVoices: availableVoices)
//}
