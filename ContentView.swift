//  ContentView.swift
//  Talkie

import SwiftUI
import AVKit
import AVFoundation
import Combine


func shouldExpandTextField() -> Bool {
    #if os(iOS)
    if UIDevice.current.userInterfaceIdiom == .pad {
        return true
    } else {
        return false
    }
    #else
    return false
    #endif
}

extension UICollectionReusableView {
  override open var backgroundColor: UIColor? {
    get { .clear }
    set { }
  }
}

@MainActor
struct ContentView: View {

    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager

  @EnvironmentObject var toolbarSettings: ToolbarSettings


  //    @Environment(\.colorScheme) var colorScheme
  //  @State var shouldAnimate: Bool = true // Add this variable
  
  @ObservedObject var viewModel: ViewModel
  @ObservedObject var settingsViewModel: SettingsViewModel
  @FocusState var isTextFieldFocused: Bool
  @ObservedObject var audioBufferPlayer = AudioBufferPlayer.shared

  @State var bottomViewOffset: CGFloat = 0
  
  @Binding var textColor: Color
  @Binding var borderColor: Color
  @Binding var backgroundColor: Color
  
  @StateObject private var bleManager = BLEManager()
  private var debounceCancellable: AnyCancellable?
  
  
  @State var keyboard = KeyboardAwareModifier(keyboardHeight: .constant(0))
  @State private var keyboardHeight: CGFloat = 0
  @State var localKeyboardHeight: CGFloat = 0 // add this line

  @Binding var isTextFieldEditing: Bool

//  @Binding var isLeftButtonToggled: Bool

  @State private var currentTextID: Int = 0

  @State private var lastMessageId: UUID? = nil

  
  //  let scrollToBottomPublisher = PassthroughSubject<Void, Never>()
  
  @State var scrollViewProxy: ScrollViewProxy? = nil // add a state variable to hold the proxy
  
  //  @ObservedObject var chatViewModel: ChatViewModel // Change this line from ChatViewModel to ViewModel
  @State var characterViewModel: CharacterViewModel
  
  @Binding var selectedCharacter: Character?
  @Binding var selectedCharacterId: String?
  @Binding var safeSelectedCharacterIndex: Int?
  var selectedCharacterIndex: Binding<Int> {
    guard let index = characterViewModel.characters.firstIndex(where: { $0.id == viewModel.selectedCharacterId }) else {
	 return .constant(0)
    }
    return Binding<Int>(
	 get: { safeSelectedCharacterIndex ?? index },
	 set: { newValue in
	   if let value = newValue as Int? {
		safeSelectedCharacterIndex = value
	   } else {
		safeSelectedCharacterIndex = index
	   }
	 }
    )
  }
  
  
  var primaryColor: Color {
    characterViewModel.characters[selectedCharacterIndex.wrappedValue].bgColor.primary
  }
  
  var secondaryColor: Color {
    characterViewModel.characters[selectedCharacterIndex.wrappedValue].bgColor.secondary
  }


  private let audioSession: AVAudioSession
  @StateObject var speechRecognitionHandler: SpeechRecognitionHandler
  @StateObject var audioRecordingHandler: AudioRecordingHandler
  @StateObject var speechSynthesizerHandler: SpeechSynthesizerHandler


    private func scrollToBottom(proxy: ScrollViewProxy) {
      guard let id = viewModel.messages.first?.id else { return }
      proxy.scrollTo(id, anchor: .top)
    }


    private func scrollToTop(proxy: ScrollViewProxy) {
      guard let id = viewModel.messages.first?.id else { return }
      proxy.scrollTo(id, anchor: .top)
    }
  

  
  init(
    viewModel: ViewModel,
    characterViewModel: CharacterViewModel,
    settingsViewModel: SettingsViewModel,
    textColor: Binding<Color>,
    borderColor: Binding<Color>,
    backgroundColor: Binding<Color>,
    selectedCharacter: Binding<Character?>,
    selectedCharacterId: Binding<String?>,
    safeSelectedCharacterIndex: Binding<Int?>,
    isTextFieldEditing: Binding<Bool>,

//    isLeftButtonToggled: Binding<Bool>,
    audioSession: AVAudioSession
  ) {

    self.viewModel = viewModel
    self._textColor = textColor
    self._borderColor = borderColor
    self._backgroundColor = backgroundColor
    self._characterViewModel = State(wrappedValue: characterViewModel)
    self.settingsViewModel = settingsViewModel

    self._selectedCharacter = selectedCharacter
    self._selectedCharacterId = selectedCharacterId
    self._safeSelectedCharacterIndex = safeSelectedCharacterIndex

    self.audioSession = audioSession

    let audioRecordingHandler = AudioRecordingHandler(viewModel: viewModel, audioBufferPlayer: AudioBufferPlayer.shared, audioSession: audioSession)
    _audioRecordingHandler = StateObject(wrappedValue: audioRecordingHandler)

    let speechSynthesizerHandler = SpeechSynthesizerHandler(viewModel: viewModel, audioBufferPlayer: AudioBufferPlayer.shared) // Initialize speechSynthesizerHandler here
    _speechSynthesizerHandler = StateObject(wrappedValue: speechSynthesizerHandler)

    let speechRecognitionHandler = SpeechRecognitionHandler(audioBufferPlayer: AudioBufferPlayer.shared, viewModel: viewModel, audioRecordingHandler: audioRecordingHandler, speechSynthesizerHandler: speechSynthesizerHandler)
    _speechRecognitionHandler = StateObject(wrappedValue: speechRecognitionHandler)

    self._isTextFieldEditing = isTextFieldEditing

//    self._isLeftButtonToggled = isLeftButtonToggled


    UICollectionView.appearance().backgroundColor = .clear
  }



  
  //  var backgroundColor: Color {
  //      return Color.black.opacity(0.9)
  //  }
  
  var body: some View {
    ZStack {
        Color.clear.edgesIgnoringSafeArea(.all)
	 VStack(spacing: 0) {
	   Spacer().frame(height: 100)
	   ScrollView {
		ScrollViewReader { scrollViewProxy in
		  LazyVStack {
		    ForEach(viewModel.messages) { message in
			 MessageListView(
			   viewModel: viewModel,
			   characterViewModel: characterViewModel,
			   selectedCharacterIndex: selectedCharacterIndex
			 )
			 .id(message.id)
			 .padding(.horizontal, 5)
			 .onTapGesture {
			   UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
			 }
		    }
		    .padding(.horizontal, 10)
		    .padding(.top, 10)
		  }
		  .onChange(of: viewModel.messages) { messages in
		    if let lastMessage = messages.last {
			 withAnimation {
			   scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
			 }
		    }
		  }
		  		}
//		.onTapGesture {
//		  hideKeyboard()
//		}
	   }
	   .mask(
//		RoundedRectangle(cornerRadius: 16, style: .continuous)
		LinearGradient(gradient: Gradient(stops: [.init(color: .clear, location: 0),
										  .init(color: Color.black.opacity(1.0), location: 0.015),
										  .init(color: Color.black.opacity(1.0), location: 0.985),
										  .init(color: .clear, location: 1)]),
					startPoint: .top,
					endPoint: .bottom)
	   )
	   .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
		let value = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
		let height = value.height
		bottomViewOffset = height
	   }
	   .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
		bottomViewOffset = 0
	   }
	   .onChange(of: viewModel.selectedCharacterId) { newValue in
		if let index = characterViewModel.characters.firstIndex(where: { $0.id == viewModel.selectedCharacterId }) {
		  safeSelectedCharacterIndex = index
		} else {
		  safeSelectedCharacterIndex = nil
		}
	   }
//	   .task {
//		viewModel.clearMessages()
//	   }
	   Spacer().frame(height: keyboardHeight + 95)
	 }
	 .onAppear(perform: KeyboardAwareModifier(keyboardHeight: $keyboardHeight).subscribeToKeyboardEvents)
	 .onTapGesture { 
	   hideKeyboard()
	 }
	   
	   // Move the overlay here
	   BottomOverlayView(
		viewModel: viewModel,
		characterViewModel: characterViewModel,
		settingsViewModel: settingsViewModel,
		backgroundColor: $backgroundColor,
		textColor: $textColor,
		borderColor: $borderColor,
		
		selectedCharacterIndex: selectedCharacterIndex,
		handleMicButtonTapped: {
		  Task {
		    await speechRecognitionHandler.handleMicButtonTapped()
		  }
		},
		isTextFieldEditing: $isTextFieldEditing

//		isLeftButtonToggled: $isLeftButtonToggled
	   )

	 if toolbarSettings.showingDropdown {
	   Color.clear
		.contentShape(Rectangle())
		.onTapGesture {
		  withAnimation {
		    toolbarSettings.showingDropdown = false
		  }
		}
	   // Rest of your code...
	 }


	 if toolbarSettings.isPresentingSettings {
	   GeometryReader { _ in
		Color.clear
		  .contentShape(Rectangle())
		  .onTapGesture {
		    withAnimation {
			 toolbarSettings.isPresentingSettings = false
		    }
		  }
	   }
	 }

    }




    .task {
	 try? await getDataFromApi()
	 try? await Task.sleep(for: Duration.seconds(4))
	 self.launchScreenState.dismiss()
    }
//    .onAppear {
//	 self.audioRecordingHandler = AudioRecordingHandler(viewModel: viewModel, audioBufferPlayer: audioBufferPlayer, audioSession: audioSession)
//	 self.speechRecognitionHandler.audioRecordingHandler = self.audioRecordingHandler
//    }

    //    .onAppear {
    //	 print("ContentView ZStack appeared!")
    //	 //	   UITableView.appearance().backgroundColor = .clear
    //	 //	   UITableViewCell.appearance().backgroundColor = .clear
    //	 //	   self.setupCommandCenter(viewModel: viewModel)
    //    }
  }


  fileprivate func getDataFromApi() async throws {
//    let googleURL = URL(string: "https://www.google.com")!
//    let (_,response) = try await URLSession.shared.data(from: googleURL)
//    print(response as? HTTPURLResponse)
  }

  func resetMessages() async {
    viewModel.clearMessages()
    // Add any additional logic to reset the API state
  }
  
  func handleMicButtonTapped() {
    Task {
	 await speechRecognitionHandler.handleMicButtonTapped()
    }
  }
  
  func handleRetry(messageRow: MessageRow)  {
     viewModel.retry(message: messageRow)
  }
  
  private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }



}

#if os(macOS)
extension NSTableView {
  open override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()

    backgroundColor = NSColor.clear
    enclosingScrollView!.drawsBackground = false
  }
}

extension NSTextView {
  open override var frame: CGRect {
    didSet {
	 backgroundColor = .clear // clear here
	 drawsBackground = true
    }
  }
}
#endif


//  class KeyboardAwareModifier: ObservableObject {
//    @Published var keyboardHeight: CGFloat = 0
//
//    private var cancellable: AnyCancellable?
//
//    deinit {
//	 cancellable?.cancel()
//    }
//
//    func listen() {
//	 cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
//	   .map { $0.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect }
//	   .map { $0.height }
//	   .subscribe(on: DispatchQueue.main)
//	   .sink { height in
//		withAnimation {
//		  self.keyboardHeight = height
//		}
//	   }
//    }
//  }
  //
  //extension View {
  //    func keyboardAware(localKeyboardHeight: Binding<CGFloat>) -> some View {
  //        self.padding(.bottom, localKeyboardHeight.wrappedValue == 0 ? 0 : -localKeyboardHeight.wrappedValue)
  //            .onPreferenceChange(ViewHeightKey.self) { newKeyboardHeight in
  //                localKeyboardHeight.wrappedValue = newKeyboardHeight
  //            }
  //    }
  //}
