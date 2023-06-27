//
//  UserPreferences.swift
//  Talkie
//
//  Created by Clif on 19/05/2023.
//

import Foundation

class UserPreferences: ObservableObject {
  @Published var characterName: String {
    didSet {
	 UserDefaults.standard.set(characterName, forKey: "name")
    }
  }

  @Published var characterAge: String {
    didSet {
	 UserDefaults.standard.set(characterAge, forKey: "age")
    }
  }

  @Published var characterInterests: String {
    didSet {
	 UserDefaults.standard.set(characterInterests, forKey: "interests")
    }
  }

  @Published var characterTopics: String {
    didSet {
	 UserDefaults.standard.set(characterTopics, forKey: "topics")
    }
  }

  init() {
    self.characterName = UserDefaults.standard.object(forKey: "name") as? String ?? ""
    self.characterAge = UserDefaults.standard.object(forKey: "age") as? String ?? ""
    self.characterInterests = UserDefaults.standard.object(forKey: "interests") as? String ?? ""
    self.characterTopics = UserDefaults.standard.object(forKey: "topics") as? String ?? ""
  }
}

