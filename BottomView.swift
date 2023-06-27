
import SwiftUI
import Combine
import MediaPlayer



struct BottomView: View {
  
  @State private var commandCenter = MPRemoteCommandCenter.shared()
  
  @FocusState private var isTextFieldFocused: Bool
  @Binding var isTextFieldEditing: Bool
  @Binding var backgroundColor: Color
  @Binding var textColor: Color
  @Binding var borderColor: Color
  
  @ObservedObject var viewModel: ViewModel
  @ObservedObject var characterViewModel: CharacterViewModel
  @ObservedObject var settingsViewModel: SettingsViewModel
  @Binding var selectedCharacterIndex: Int
  
  @State private var keyboardHeight: CGFloat = 0
  @State var bottomViewOffset: CGFloat = 0
  @State private var selectedCharacter: Character?

//  @Binding var isPresentingSettings: Bool
  @EnvironmentObject var toolbarSettings: ToolbarSettings


  //  @Binding var isLeftButtonToggled: Bool
  
  var handleMicButtonTapped: () async -> Void
  
  @State var safeSelectedCharacterIndex: Int? = nil
  
  init(viewModel: ViewModel,
	  characterViewModel: CharacterViewModel,
	  settingsViewModel: SettingsViewModel,
	  backgroundColor: Binding<Color>,
	  textColor: Binding<Color>,
	  borderColor: Binding<Color>,
	  selectedCharacterIndex: Binding<Int>,
	  isTextFieldEditing: Binding<Bool>,

	  //	  isLeftButtonToggled: Binding<Bool>,
	  handleMicButtonTapped: @escaping () async -> Void)
  {
self.viewModel = viewModel
self.characterViewModel = characterViewModel
self.settingsViewModel = settingsViewModel
self._backgroundColor = backgroundColor
self._textColor = textColor
self._borderColor = borderColor
self._selectedCharacterIndex = selectedCharacterIndex
self._safeSelectedCharacterIndex = State(initialValue: selectedCharacterIndex.wrappedValue)
self.handleMicButtonTapped = handleMicButtonTapped

//self._isTextFieldFocused = .init(initialValue: false)
self._isTextFieldEditing = isTextFieldEditing
//self._isLeftButtonToggled = isLeftButtonToggled
  }
  
  private func initializeSelectedCharacter() {
    if let selectedIndex = safeSelectedCharacterIndex, selectedIndex < characterViewModel.characters.count {
	 selectedCharacter = characterViewModel.characters[selectedIndex]
    } else {
	 selectedCharacter = characterViewModel.characters.first
    }
  }
  
  private var bottomPadding: CGFloat {
    return keyboardHeight
  }
  
  var body: some View {
    GeometryReader { geometry in
	 bottomView(
	   geometry: geometry,
	   image: "image",
	   viewModel: viewModel,
	   isTextFieldFocused: _isTextFieldFocused,
	   characterViewModel: characterViewModel,
	   shouldExpandTextField: false,
	   keyboardHeight: keyboardHeight
	 )
    }
    .onAppear {
	 initializeSelectedCharacter()
    }
  }
  
  func bottomView(
    geometry: GeometryProxy,
    image: String,
    viewModel: ViewModel,
    isTextFieldFocused: FocusState<Bool>,
    characterViewModel: CharacterViewModel,
    shouldExpandTextField: Bool,
    keyboardHeight: CGFloat
  ) -> some View {
    VStack {
	 Spacer()
	 
	 HStack(spacing: 0) {

	   if settingsViewModel.isLeftButtonToggled {
		
		BottomButton(isTextFieldFocused: isTextFieldFocused, viewModel: viewModel, characterViewModel: characterViewModel, handleMicButtonTapped: handleMicButtonTapped, isPresentingSettings: $toolbarSettings.isPresentingSettings)
		  .transition(.move(edge: .leading))
		BottomTextField(viewModel: viewModel, characterViewModel: characterViewModel, isTextFieldEditing: $isTextFieldEditing, isTextFieldFocused: isTextFieldFocused)
		  .padding(.trailing, 24)
		  .transition(.offset(x: -81))

	   } else {
		
		BottomTextField(viewModel: viewModel, characterViewModel: characterViewModel, isTextFieldEditing: $isTextFieldEditing, isTextFieldFocused: isTextFieldFocused)
		  .padding(.leading, 24)
		  .transition(.offset(x: 81))
		BottomButton(isTextFieldFocused: isTextFieldFocused, viewModel: viewModel, characterViewModel: characterViewModel, handleMicButtonTapped: handleMicButtonTapped, isPresentingSettings: $toolbarSettings.isPresentingSettings)
		  .transition(.move(edge: .trailing))
	   }
	   
	   
	 }
//	 .opacity(toolbarSettings.showingDropdown ? 0 : 0.95)
//	 .opacity(toolbarSettings.isPresentingSettings ? 0 : 0.95)
	 .animation(.easeOut(duration: 0.4))
	  // Specify transition type
	 .onChange(of: settingsViewModel.isLeftButtonToggled) { value in
	   if value {
		withAnimation(Animation.easeInOut(duration: 1.0)) {
		  // Change properties that should be animated here
		}
	   }
	 }
	 .background(Color.clear.opacity(0.95))
	 .padding(.bottom, 2)
	 .padding(.vertical, 0)

	 .frame(maxWidth: .infinity, alignment: .bottom) // Add alignment guide
    }.modifier(KeyboardAwareModifier(keyboardHeight: $keyboardHeight))
	 .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  }
}


  struct BottomButton: View {
    @FocusState var isTextFieldFocused: Bool
    var viewModel: ViewModel
    var characterViewModel: CharacterViewModel
    var handleMicButtonTapped: () async -> Void
    @Binding var isPresentingSettings: Bool

    var body: some View {
	 Button(action: {
	   if isTextFieldFocused {
		Task {
		  await viewModel.sendTapped(text: viewModel.inputMessage, characterViewModel: characterViewModel)
		  viewModel.inputMessage = "" // Clear input field after sending message
		}
		hideKeyboard()
	   } else {
		Task {
		  await handleMicButtonTapped()
		}
	   }
	 })
	   {
	   Image(isTextFieldFocused ? "send" : (viewModel.isMicButtonPressed ? "send" : "mic"))
		.resizable()
		.frame(width: 85, height: 85)
		.font(.system(size: 70))
		.foregroundColor(isTextFieldFocused ? .green : (viewModel.isMicButtonPressed ? .red : .green))
		.padding(.horizontal, 10)
		.padding(.bottom, -2)
		.scaleEffect(viewModel.isMicButtonPressed ? viewModel.micButtonScale : 1)

	 }

	 .onChange(of: viewModel.isMicButtonPressed) { _ in
	   viewModel.micButtonScale = viewModel.isMicButtonPressed ? 1.0 : 1.2
	 }

    }
  }

  struct BottomTextField: View {
    var viewModel: ViewModel
    var characterViewModel: CharacterViewModel
    @Binding var isTextFieldEditing: Bool
    @FocusState var isTextFieldFocused: Bool

    var body: some View {
	 ExpandingTextField(text: viewModel.binding(for: \.inputMessage), onCommit: {
	   Task {
		await viewModel.sendTapped(text: viewModel.inputMessage, characterViewModel: characterViewModel)
		viewModel.inputMessage = "" // Clear input field after sending message
	   }
	   hideKeyboard()
	 })
	 .frame(minHeight: 35, maxHeight: 55)
	 .focused($isTextFieldFocused)
	 .multilineTextAlignment(.leading)
	 .keyboardType(.default)
	 .onChange(of: isTextFieldFocused) { isFocused in
	   self.isTextFieldEditing = isFocused
	 }
    }
  }





//  struct SolidButtonStyle: ButtonStyle {
//    func makeBody(configuration: Self.Configuration) -> some View {
//	 configuration.label
//	   .opacity(configuration.isPressed ? 1.0 : 1.0) // Set the opacity based on the button's state
//	   .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Optionally, add a scale effect
//    }
//  }

  private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }

struct KeyboardAwareModifier: ViewModifier {
  @Binding var keyboardHeight: CGFloat

  init(keyboardHeight: Binding<CGFloat>) {
    self._keyboardHeight = keyboardHeight
  }

  func body(content: Content) -> some View {
    content
	 .padding(.bottom, keyboardHeight)
	 .animation(.easeOut(duration: 0.16), value: keyboardHeight)
	 .onAppear(perform: subscribeToKeyboardEvents)
  }

   func subscribeToKeyboardEvents() {
    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (notification) in
	 guard let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
	 keyboardHeight = keyboardSize.height
    }

    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
	 keyboardHeight = 0
    }
  }
}

struct BounceEffect: AnimatableModifier {
  var progress: CGFloat
  var amplitude: CGFloat

  var animatableData: CGFloat {
    get { progress }
    set { progress = newValue }
  }

  func body(content: Content) -> some View {
    let bounce = 1.0 + sin(progress * .pi * 2) * amplitude
    return content
	 .scaleEffect(CGSize(width: bounce, height: bounce))
  }
}

extension View {
  func bounceEffect(progress: CGFloat, amplitude: CGFloat) -> some View {
    self.modifier(BounceEffect(progress: progress, amplitude: amplitude))
  }
  func keyboardAware(localKeyboardHeight: Binding<CGFloat>) -> some View {
    self
	 .overlay(GeometryReader { proxy in
	   Color.clear
		.preference(key: ViewHeightKey.self, value: proxy.frame(in: .global).minY)
	 })
	 .onPreferenceChange(ViewHeightKey.self) { minY in
	   let keyboardTop = UIScreen.main.bounds.height - localKeyboardHeight.wrappedValue
	   let focusedViewBottom = minY

	   if keyboardTop < focusedViewBottom {
		localKeyboardHeight.wrappedValue = focusedViewBottom - keyboardTop
	   }
	 }
  }
}

extension Animation {
  func repeatWhile(_ condition: Bool) -> Animation {
    return condition ? self.repeatForever() : self
  }
}

struct ViewHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

extension ObservableObject {
  func binding<Value>(for keyPath: ReferenceWritableKeyPath<Self, Value>) -> Binding<Value> {
    return Binding<Value>(
	 get: { self[keyPath: keyPath] },
	 set: { self[keyPath: keyPath] = $0 }
    )
  }
}

extension View {
  func animatableGradient(fromGradient: Gradient, toGradient: Gradient, progress: CGFloat) -> some View {
    self.modifier(AnimatableGradientModifier(fromGradient: fromGradient, toGradient: toGradient, progress: progress))
  }
}

struct AnimatableGradientModifier: AnimatableModifier {
  let fromGradient: Gradient
  let toGradient: Gradient
  var progress: CGFloat = 0.0

  var animatableData: CGFloat {
    get { progress }
    set { progress = newValue }
  }

  func body(content: Content) -> some View {
    var gradientColors = [Color]()

    for i in 0..<fromGradient.stops.count {
	 let fromColor = UIColor(fromGradient.stops[i].color)
	 let toColor = UIColor(toGradient.stops[i].color)

	 gradientColors.append(colorMixer(fromColor: fromColor, toColor: toColor, progress: progress))
    }

    return LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
  }

  func colorMixer(fromColor: UIColor, toColor: UIColor, progress: CGFloat) -> Color {
    guard let fromColor = fromColor.cgColor.components else { return Color(fromColor) }
    guard let toColor = toColor.cgColor.components else { return Color(toColor) }

    let red = fromColor[0] + (toColor[0] - fromColor[0]) * progress
    let green = fromColor[1] + (toColor[1] - fromColor[1]) * progress
    let blue = fromColor[2] + (toColor[2] - fromColor[2]) * progress

    return Color(red: Double(red), green: Double(green), blue: Double(blue))
  }
}

extension View {
  func chatBubbleShape(isUser: Bool) -> some View {
    self.clipShape(FlippableRoundedRectangle(cornerRadius: 16, style: .continuous, shouldFlip: isUser))
  }
}

struct DismissKeyboardOnTap: ViewModifier {
  func body(content: Content) -> some View {
    content
	 .gesture(
	   TapGesture()
		.onEnded { _ in
		  dismissKeyboard()
		}
	 )
	 .gesture(
	   DragGesture(minimumDistance: 5)
		.onEnded { _ in
		  dismissKeyboard()
		}
	 )
  }

  private func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

extension View {
  func dismissKeyboardOnTap() -> some View {
    self.modifier(DismissKeyboardOnTap())
  }
}

struct LineView: View {
  var text: String
  var isHighlighted: Bool

  var body: some View {
    Text(text)
	 .padding()
	 .background(isHighlighted ? Color.yellow : Color.clear)
	 .animation(.easeInOut, value: isHighlighted)
  }
}
