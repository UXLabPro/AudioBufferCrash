//
//  BottomOverlayView.swift
//  Talkie
//
//  Created by Clif on 03/04/2023.
//

import Foundation
import SwiftUI

struct BottomOverlayView: View {

//  @Binding private var isTextFieldFocused: Bool



  @ObservedObject var viewModel: ViewModel
  @ObservedObject var characterViewModel: CharacterViewModel
  @ObservedObject var settingsViewModel: SettingsViewModel
  @Binding var backgroundColor: Color
  @Binding var textColor: Color
  @Binding var borderColor: Color
  @Binding var selectedCharacterIndex: Int
  var handleMicButtonTapped: () -> Void
  @Binding var isTextFieldEditing: Bool

//  @Binding var isLeftButtonToggled: Bool


  var body: some View {
    BottomView(
	 viewModel: viewModel,
	 characterViewModel: characterViewModel,
	 settingsViewModel: settingsViewModel,
//	 isTextFieldFocused: isTextFieldFocused,
	 backgroundColor: $backgroundColor,
	 textColor: $textColor,
	 borderColor: $borderColor,
	 selectedCharacterIndex: $selectedCharacterIndex,
	 isTextFieldEditing: $isTextFieldEditing,

//	 isLeftButtonToggled: $isLeftButtonToggled,
	 handleMicButtonTapped: handleMicButtonTapped
    )

    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .padding(.top, 80)
    .padding(.bottom, 10)
  }
}
