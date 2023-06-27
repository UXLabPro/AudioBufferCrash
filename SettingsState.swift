//
//  SettingsState.swift
//  Talkie
//
//  Created by Clif on 27/05/2023.
//

import Foundation

class SettingsState: ObservableObject {
  @Published var isPreserveMessagesEnabled: Bool {
    didSet {
	 UserDefaults.standard.set(isPreserveMessagesEnabled, forKey: "isPreserveMessagesEnabled")
    }
  }


  // Add other properties as needed

  init() {
    self.isPreserveMessagesEnabled = UserDefaults.standard.bool(forKey: "isPreserveMessagesEnabled")
    // Initialize other properties from UserDefaults
  }
}

// UserSettings.swift
class UserSettings: ObservableObject {
  @Published var editedCharacter: Character? // Stores the locally edited Character
}
