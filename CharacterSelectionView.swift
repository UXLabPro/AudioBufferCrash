//
//  CharacterSelectionView.swift
//  Talkie
//
//  Created by Clif on 24/03/2023.
//

import SwiftUI

extension CharacterColor: Equatable {
  static func == (lhs: CharacterColor, rhs: CharacterColor) -> Bool {
    return lhs.primary == rhs.primary && lhs.secondary == rhs.secondary
  }
}

struct DropdownMenuView: View {
//  @Binding var showingDropdown: Bool
  @ObservedObject var characterViewModel: CharacterViewModel
  @ObservedObject var vm: ViewModel
  @Binding var selectedCharacter: Character?
  @ObservedObject var characterSettingsViewModel: CharacterSettingsViewModel
//  @EnvironmentObject var toolbarSettings: ToolbarSettings

  var body: some View {
    HStack {
	 ZStack {
	   Group {
		CharacterSelectionView(
		  chatGPTAPI: vm.api,
		  characterViewModel: characterViewModel,
		  selectedCharacter: $selectedCharacter,
		  characterSettingsViewModel: characterSettingsViewModel,
//		  showingDropdown: $showingDropdown,
		  onUpdateSelectedCharacter: { character, chatGPTAPI in
		    chatGPTAPI.updateCharacter(newCharacter: character)
		  }
		)
	   }
	   .padding(EdgeInsets())
	   .frame(width: 300)
	   .cornerRadius(15)
	   .padding(.leading, 5)
	 }
	 .background(Color.clear.mask(RoundedRectangle(cornerRadius: 15, style: .circular)))
	 Spacer()
    }
    .padding(.bottom, 0)
    .padding(.top, 0)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .transition(.move(edge: .leading))
  }
}

struct CharacterSelectionView: View {
//  @Environment(\.colorScheme) var colorScheme

  @ObservedObject var chatGPTAPI: ChatGPTAPI
  @ObservedObject var characterViewModel: CharacterViewModel


  @Binding var selectedCharacter: Character?
  @ObservedObject var characterSettingsViewModel: CharacterSettingsViewModel
  @EnvironmentObject var toolbarSettings: ToolbarSettings
//  @Binding var showingDropdown: Bool
  //    @Binding var selectedCharacterIndex: Int?

  var onUpdateSelectedCharacter: (Character, ChatGPTAPI) -> Void

  func buttonColors(for character: Character) -> CharacterColor? {
    return characterViewModel.randomizedCharacters.first(where: { $0.id == character.id })?.bgColor
  }

 


  var body: some View {
    VStack {
	 ZStack {
	   
	   List {
		ForEach(0..<characterViewModel.randomizedCharacters.count, id: \.self) { index in
		  Button(action: {
		    withAnimation(.easeInOut(duration: 1.0)) {
			 selectedCharacter = characterViewModel.randomizedCharacters[index]
			 characterViewModel.selectedCharacter = characterViewModel.randomizedCharacters[index] // Add this line
			 characterViewModel.selectedCharacterIndex = index
			 toolbarSettings.showingDropdown = false
			 onUpdateSelectedCharacter(characterViewModel.randomizedCharacters[index], chatGPTAPI)
			 characterSettingsViewModel.updateCharacterSettings(for: characterViewModel.randomizedCharacters[index])
			 characterViewModel.moveSelectedCharacterToTop()
		    }
		  }, label: {
		    HStack {
			 Image("character")
			   .resizable()
			   .frame(width: 50, height: 50)
			   .aspectRatio(contentMode: .fit)
			   .background(Color.clear)
			   .padding(.leading, -13)
			   .opacity(0.85)
			 Text(characterViewModel.randomizedCharacters[index].name)
			   .font(.system(size: 20.0, weight: .black, design: .rounded))
			   .foregroundColor(.white).opacity(0.65)
			   .frame(width: 210, alignment: .leading)
			   .lineLimit(1)
			   .padding(.leading, 1)
			   .padding(.top, 15)
		    }
		    .padding(.trailing, toolbarSettings.showingDropdown ? 0 : 0)
		    .listRowSeparator(.hidden)
		    .padding(.vertical, 10)
		    .padding(.leading, 32)
		    .background(RoundedRectangle(cornerRadius: 15).fill(buttonColors(for: characterViewModel.randomizedCharacters[index])?.primary ?? Color.clear).opacity(0.5))
		    .overlay(
			 RoundedRectangle(cornerRadius: 15)
			   .stroke(characterViewModel.selectedCharacter?.id == characterViewModel.randomizedCharacters[index].id ? Color.white : Color.clear, lineWidth: 1).opacity(0.65)
		    )
		    
		  })
		  .buttonStyle(BorderlessButtonStyle())
		  .padding(.bottom, -5)
		  .padding(.leading, 22)
		  .listRowBackground(Color.clear)
		  .listRowSeparatorTint(.clear)
		}
		.listStyle(SidebarListStyle())
	   }
	   .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
	   .background(Color.clear)
	   .padding(EdgeInsets())
	   .listRowInsets(EdgeInsets())
	   .scrollContentBackground(.hidden)
	   .padding(.leading, -12)
	   .padding(.top, 16)
	   .onChange(of: selectedCharacter) { newSelectedCharacter in
		characterViewModel.selectedCharacter = newSelectedCharacter
		if let character = newSelectedCharacter {
		  print(character.name)
		}
	   }
	   .onAppear {
		if characterViewModel.randomizedCharacters.isEmpty {
		  characterViewModel.randomizeCharacters()
		}
		if characterViewModel.selectedCharacter == nil {
		  characterViewModel.moveExceptionCharactersToTop()
		} else {
		  characterViewModel.moveSelectedCharacterToTop()
		}
	   }

	   VStack {
		HStack {
		  
		  Button(action: {
		    characterViewModel.randomizeCharacters()
		  }) {
		    VStack {
			 ZStack {
			   Circle()
				.fill(Color.black.opacity(0.85))
				.frame(width: 33)
			   Image(systemName: "shuffle.circle")
				.foregroundColor(Color.white.opacity(0.65))
				.font(.system(size: 35.0, weight: .thin, design: .rounded))

			   //		Text("Shuffle")
			   //		    .frame(width: 55, height: 15)
			   //		  .foregroundColor(Color.white.opacity(0.65))
			   //		  .font(.system(size: 14.0, weight: .heavy, design: .rounded))
			   //		  .lineLimit(1)
			 }
		    }
		  }
		  .disabled(false)
		  .buttonStyle(PlainButtonStyle())
		  .foregroundColor(.white)
		  .allowsHitTesting(true)
		  Spacer()
		  
		  //
		  //
		  //	   Button(action: {
		  //		characterViewModel.randomizeCharacters()
		  //	   }) {
		  //		VStack {
		  //		  Image(systemName: "circle.grid.3x3.circle")
		  //		    .foregroundColor(Color.white.opacity(0.65))
		  //		    .font(.system(size: 50.0, weight: .thin, design: .rounded))
		  //		  Text("Grid")
		  //		    .frame(width: 55, height: 15)
		  //		    .foregroundColor(Color.white.opacity(0.65))
		  //		    .font(.system(size: 14.0, weight: .heavy, design: .rounded))
		  //		    .lineLimit(1)
		  //		}
		  //	   }
		  //	   .disabled(true)
		  //	   .buttonStyle(PlainButtonStyle())
		  //	   .background(Color.black.opacity(0))
		  //	   .foregroundColor(.white)
		  //	   .allowsHitTesting(true)
		  //	   Spacer()
		  //		.frame(width: 15)
		  //
		  //
		  //
		  //	   Button(action: {
		  //		characterViewModel.randomizeCharacters()
		  //	   }) {
		  //		VStack {
		  //		  Image(systemName: "pencil.circle")
		  //		    .foregroundColor(Color.white.opacity(0.65))
		  //		    .font(.system(size: 50.0, weight: .thin, design: .rounded))
		  //		  Text("Edit")
		  //		    .frame(width: 55, height: 15)
		  //		    .foregroundColor(Color.white.opacity(0.65))
		  //		    .font(.system(size: 14.0, weight: .heavy, design: .rounded))
		  //		    .lineLimit(1)
		  //		}
		  //	   }
		  //	   .disabled(true)
		  //	   .buttonStyle(PlainButtonStyle())
		  //	   .background(Color.black.opacity(0))
		  //	   .foregroundColor(.white)
		  //	   .allowsHitTesting(true)
		  //	   Spacer()
		  //		.frame(width: 15)
		  //
		  //
		  //
		  //
		  //	   Button(action: {
		  //		characterViewModel.randomizeCharacters()
		  //	   }) {
		  //		VStack {
		  //		  Image(systemName: "plus.circle")
		  //		    .foregroundColor(Color.white.opacity(0.65))
		  //		    .font(.system(size: 50.0, weight: .thin, design: .rounded))
		  //		  Text("Add")
		  //		    .frame(width: 55, height: 15)
		  //		    .foregroundColor(Color.white.opacity(0.65))
		  //		    .font(.system(size: 14.0, weight: .heavy, design: .rounded))
		  //		    .lineLimit(1)
		  //		}
		  //	   }
		  //	   .disabled(true)
		  //	   .buttonStyle(PlainButtonStyle())
		  //	   .background(Color.black.opacity(0))
		  //	   .foregroundColor(.white)
		  //	   .allowsHitTesting(true)
		  //
		  
		}.padding(.top, 10)
		  .padding(.leading, 40)
		Spacer()
	   }
	 }
    }
  }
}
