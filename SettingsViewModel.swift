//
//  SettingsViewModel.swift
//  Talkie
//
//  Created by Clif on 03/04/2023.
//

import SwiftUI

class SettingsViewModel: ObservableObject {

  @Published var settingsState: SettingsState
  @Published var userSettings: UserSettings

  @ObservedObject var characterViewModel: CharacterViewModel
  @ObservedObject var characterSettingsViewModel: CharacterSettingsViewModel

  @Binding var isPresented: Bool

  @Published var isRecordMode: Bool = false


  @Published var colorNames: [String: String] = UserDefaults.standard.dictionary(forKey: "colorNames") as? [String: String] ?? [:]
  @Published var isLeftButtonToggled = false

  @Published var talkieRapport: String = ""
  @Published var talkieFormat: String = ""
  @Published var talkieBio: String = ""
  @Published var character: Character?

  @AppStorage("name") var name: String = ""
  @AppStorage("age") var age: String = ""
  @AppStorage("interests") var interests: String = ""
  @AppStorage("topics") var topics: String = ""

  @AppStorage("timer") var timerData: Data = Data()
  @AppStorage("alarm") var alarmData: Data = Data()

  @AppStorage("characterName") var characterName: String = ""
  @AppStorage("voiceIdentifier") var voiceIdentifier: String = ""
  @AppStorage("characterDescription") var characterDescription: String = ""


  @Published var basicCharacterDescription: String = ""
  @Published var primaryColorString: String = ""
  @Published var secondaryColorString: String = ""

  @Published var characterImage1: UIImage?
  @Published var characterImage2: UIImage?
  @Published var characterImage3: UIImage?
  @Published var characterImage4: UIImage?

  


  // TODO - ADD IMAGE AND COLOURS
  @Published var bubbleColor: Color = Color.clear
  @AppStorage("bluetoothDevice") var bluetoothDevice: String = ""
  @AppStorage("airplayDevice") var airplayDevice: String = ""
  @AppStorage("audioIODevice") var audioIODevice: String = ""


  func setImage(_ image: UIImage?, forKey key: String) {
    guard let image = image else {
	 UserDefaults.standard.set(nil, forKey: key)
	 return
    }

    guard let data = image.pngData() else {
	 return
    }

    UserDefaults.standard.set(data, forKey: key)

    switch key {
	 case "characterImage1":
	   characterImage1 = image
	 case "characterImage2":
	   characterImage2 = image
	 case "characterImage3":
	   characterImage3 = image
	 case "characterImage4":
	   characterImage4 = image
	 default:
	   break
    }
  }

  func selectImage(_ image: UIImage?, forIndex index: Int) {
    switch index {
	 case 1:
	   characterImage1 = image
	   setImage(image, forKey: "characterImage1")
	 case 2:
	   characterImage2 = image
	   setImage(image, forKey: "characterImage2")
	 case 3:
	   characterImage3 = image
	   setImage(image, forKey: "characterImage3")
	 case 4:
	   characterImage4 = image
	   setImage(image, forKey: "characterImage4")
	 default:
	   break
    }
  }


  func getImageForKey(_ key: String) -> UIImage? {
    guard let data = UserDefaults.standard.object(forKey: key) as? Data else {
	 return nil
    }

    return UIImage(data: data)
  }


  var timer: Date {
    get {
	 return decodeDate(from: timerData)
    }
    set {
	 timerData = encodeDate(newValue)
    }
  }

  var alarm: Date {
    get {
	 return decodeDate(from: alarmData)
    }
    set {
	 alarmData = encodeDate(newValue)
    }
  }


  init(isPresented: Binding<Bool>, userSettings: UserSettings, characterViewModel: CharacterViewModel, characterSettingsViewModel: CharacterSettingsViewModel) {
    self.settingsState = SettingsState()
    self.userSettings = userSettings
    self._isPresented = isPresented
    self.characterViewModel = characterViewModel
    self.characterSettingsViewModel = characterSettingsViewModel

    if let currentCharacter = characterViewModel.selectedCharacter {
	 self.characterName = currentCharacter.name
	 self.voiceIdentifier = currentCharacter.voiceIdentifier
	 self.characterDescription = currentCharacter.description
	 let primaryUIColor = UIColor(currentCharacter.bgColor.primary) // Use UIColor initializer that can take a SwiftUI Color as parameter. You might need to create a UIColor extension for this
	 let secondaryUIColor = UIColor(currentCharacter.bgColor.secondary) // The same here
	 self.primaryColorString = primaryUIColor.rgba
	 self.secondaryColorString = secondaryUIColor.rgba
	 self.basicCharacterDescription = characterViewModel.basicCharacterDescription
	 characterImage1 = getImageForKey("characterImage1")
	 characterImage2 = getImageForKey("characterImage2")
	 characterImage3 = getImageForKey("characterImage3")
	 characterImage4 = getImageForKey("characterImage4")
    }
  }



  func saveSettings(
    name: String,
    age: String,
    topics: String,
    interests: String,
    characterName: String,
    voiceIdentifier: String,
    characterDescription: String,
    primaryColor: Color,
    secondaryColor: Color
//    bubbleColor: Color
  ) {
    self.name = name
    self.age = age
    self.topics = topics
    self.interests = interests
    characterSettingsViewModel.characterName = characterName
    characterSettingsViewModel.voiceIdentifier = voiceIdentifier
    characterSettingsViewModel.characterDescription = characterDescription
    let colorManager = ColorManager.shared
    colorManager.primaryColor = primaryColor
    colorManager.secondaryColor = secondaryColor
    characterSettingsViewModel.primaryColor = primaryColor
    characterSettingsViewModel.secondaryColor = secondaryColor
//    characterSettingsViewModel.bubbleColor = bubbleColor
    UserDefaults.standard.synchronize() // Make sure to synchronize UserDefaults

    $isPresented.wrappedValue.toggle()
  }


  func saveSettings() {
    if name.isEmpty {
	 name = ""
    }
    if age.isEmpty {
	 age = ""
    }
//    if bubbleColor == .clear {
//	 bubbleColor = characterViewModel.safeSecondaryColorAsColor(at: 0)
//    }
    colorNames = colorNames // This line automatically saves colorNames to UserDefaults due to the UserDefaultsBacked property wrapper.
    UserDefaults.standard.set(name, forKey: "name")
    UserDefaults.standard.set(age, forKey: "age")
    UserDefaults.standard.set(characterName, forKey: "characterName")
    UserDefaults.standard.set(voiceIdentifier, forKey: "voiceIdentifier")
    UserDefaults.standard.set(characterDescription, forKey: "characterDescription")
//    UserDefaults.standard.set(primaryColor.uiColor().rgba, forKey: "primaryColor")
//    UserDefaults.standard.set(secondaryColor.uiColor().rgba, forKey: "secondaryColor")
//    UserDefaults.standard.set(bubbleColor.toHex().hexToInt(), forKey: "bubbleColor")
    UserDefaults.standard.set(colorNames, forKey: "colorNames")
    $isPresented.wrappedValue.toggle()
  }

  func updateBubbleColor(from characterViewModel: CharacterViewModel) {
    bubbleColor = characterViewModel.safeSecondaryColorAsColor(at: 0)
  }

  private func encodeDate(_ date: Date) -> Data {
    let encoder = JSONEncoder()
    do {
	 return try encoder.encode(date)
    } catch {
	 // Handle encoding error
	 return Data()
    }
  }

  private func decodeDate(from data: Data) -> Date {
    let decoder = JSONDecoder()
    do {
	 return try decoder.decode(Date.self, from: data)
    } catch {
	 // Handle decoding error
	 return Date()
    }
  }
  
  func clearMessages() {
    if settingsState.isPreserveMessagesEnabled {
	 // Preserve messages logic here
    } else {
	 // Clear messages logic here
    }
  }
}


