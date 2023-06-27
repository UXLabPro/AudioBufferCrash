//
//  CharacterSettingsViewModel.swift
//  Talkie
//
//  Created by Clif on 12/06/2023.
//

import Foundation
import SwiftUI
import Combine

class CharacterSettingsViewModel: ObservableObject {
  @ObservedObject var characterViewModel: CharacterViewModel
  @Published var character: Character?

  @AppStorage("name") var name: String = ""
  @AppStorage("age") var age: String = ""
  @AppStorage("interests") var interests: String = ""
  @AppStorage("topics") var topics: String = ""

  @AppStorage("characterName") var characterName: String = ""
  @AppStorage("voiceIdentifier") var voiceIdentifier: String = ""
  @AppStorage("characterDescription") var characterDescription: String = ""
  @Published var basicCharacterDescription: String = ""

  @Published var characterImage1: UIImage?
  @Published var characterImage2: UIImage?
  @Published var characterImage3: UIImage?
  @Published var characterImage4: UIImage?

  @UserDefaultsBacked(key: "primaryColor", defaultValue: "#ffffff", suite: .appGroup) var primaryColorString: String
  @UserDefaultsBacked(key: "secondaryColor", defaultValue: "#ffffff", suite: .appGroup) var secondaryColorString: String

  var colorManager = ColorManager.shared

  @Published var primaryColor: Color
  @Published var secondaryColor: Color
  @Published var selectedCharacterIndex: Int?

  private var cancellables = Set<AnyCancellable>()

  // Initialize with a character
  init(characterViewModel: CharacterViewModel, character: Character) {
    self.characterViewModel = characterViewModel
    self.character = character
    self.primaryColor = characterViewModel.PrimaryColor
    self.secondaryColor = characterViewModel.SecondaryColor

    characterViewModel.$selectedCharacter
	 .sink { [weak self] character in
	   if let character = character {
		self?.updateCharacterSettings(for: character)
	   }
	 }
	 .store(in: &cancellables)

    // Subscribe to changes in characterViewModel.selectedCharacter and update primaryColor and secondaryColor when it changes
    // You can use Combine's Publishers for this.
    // You'll need to store the cancellable somewhere (like in a Set<AnyCancellable>) to prevent the subscription from being deallocated.
    // Load settings for the character
    loadCharacterSettings()
  }

//  var characterName: String {
//    didSet {
//	 saveCharacterSettings()
//    }
//  }
//
//  var characterDescription: String {
//    didSet {
//	 saveCharacterSettings()
//    }
//  }

  private func saveCharacterSettings() {
    // Save settings for the character to AppStorage or wherever they're stored
    let characterSettings: [String: Any] = ["characterName": characterName, "characterDescription": characterDescription]
    if let characterId = character?.id {
	 UserDefaults.standard.set(characterSettings, forKey: characterId)
    }
  }

  func changeCharacterColors(character: Character, primary: Color, secondary: Color) {
    // Update colors here...
  }

  func changeCharacterColor(primaryColor: UIColor, secondaryColor: UIColor) {
    characterViewModel.colorManager.primaryColor = Color(primaryColor)
    characterViewModel.colorManager.secondaryColor = Color(secondaryColor)
    self.primaryColor = Color(primaryColor)
    self.secondaryColor = Color(secondaryColor)
  }

  func selectCharacter(at index: Int) {
    characterViewModel.selectedCharacterIndex = index
  }

  private func loadCharacterSettings() {
    // Load settings for the character from AppStorage or wherever they're stored
    if let characterId = character?.id {
	 let characterSettings = UserDefaults.standard.object(forKey: characterId) as? [String: Any]
	 if let characterSettings = characterSettings {
	   // Update the properties of the CharacterSettingsViewModel based on the loaded settings
	   self.characterName = characterSettings["characterName"] as? String ?? ""
	   self.characterDescription = characterSettings["characterDescription"] as? String ?? ""
	   // Add more properties as needed
	 }
    }
  }


  func updateCharacterSettings(for character: Character) {
    self.character = character
    loadCharacterSettings()
  }

  func saveSettings(
    name: String,
    age: String,
    characterName: String,
    voiceIdentifier: String,
    characterDescription: String,
    primaryColor: String,
    secondaryColor: String
  ) {
    self.name = name
    self.age = age
    self.characterName = characterName
    self.voiceIdentifier = voiceIdentifier
    self.characterDescription = characterDescription
    self.primaryColorString = primaryColor
    self.secondaryColorString = secondaryColor
  }



//  var primaryColor: Color {
//    get {
//	 return Color(uiColor: UIColor(rgba: primaryColorString) ?? UIColor.white)
//    }
//    set {
//	 primaryColorString = newValue.uiColor().rgba
//    }
//  }
//
//  var secondaryColor: Color {
//    get {
//	 return Color(uiColor: UIColor(rgba: secondaryColorString) ?? UIColor.white)
//    }
//    set {
//	 secondaryColorString = newValue.uiColor().rgba
//    }
//  }

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
}
