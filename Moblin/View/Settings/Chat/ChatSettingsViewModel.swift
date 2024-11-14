import SwiftUI

// ViewModel for ChatSettingsView
class ChatSettingsViewModel: ObservableObject {
    // Published properties for binding to the UI
    @Published var isEnabled: Bool = false
    @Published var fontSize: Float = 
    @Published var height: Double
    @Published var width: Double
    @Published var timestampColor: Color
    @Published var usernameColor: Color
    @Published var messageColor: Color
    @Published var backgroundColor: Color
    @Published var shadowColor: Color

    // Methods for updating settings
    func toggleEnabled() {
        isEnabled.toggle()
        saveChanges()
    }

    func updateFontSize(to value: Float) {
        fontSize = value
        saveChanges()
    }

    func updateHeight(to value: Double) {
        height = value
        saveChanges()
    }

    func updateWidth(to value: Double) {
        width = value
        saveChanges()
    }

    func updateTimestampColor(to color: Color) {
        timestampColor = color
        saveChanges()
    }

    func updateUsernameColor(to color: Color) {
        usernameColor = color
        saveChanges()
    }

    func updateMessageColor(to color: Color) {
        messageColor = color
        saveChanges()
    }

    // Simulated save logic
    private func saveChanges() {
        // Here you would update the model/database
        print("Saved changes to chat settings")
    }
}
