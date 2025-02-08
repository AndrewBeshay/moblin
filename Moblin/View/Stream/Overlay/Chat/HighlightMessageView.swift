import SwiftUI
import WrappingHStack

private let borderWidth = 1.5

/// A view that renders a highlighted chat message with custom styling.
/// You can customize the background color, font, and other properties to suit your app’s design.
struct HighlightMessageView: View {
    let chat: SettingsChat
    let image: String
    let name: String

    private func messageColor() -> Color {
        return chat.messageColor.color()
    }

    private func backgroundColor() -> Color {
        if chat.backgroundColorEnabled {
            return chat.backgroundColor.color().opacity(0.6)
        } else {
            return .clear
        }
    }

    private func shadowColor() -> Color {
        if chat.shadowColorEnabled {
            return chat.shadowColor.color()
        } else {
            return .clear
        }
    }

    var body: some View {
        let messageColor = messageColor()
        let shadowColor = shadowColor()
        WrappingHStack(
            alignment: .leading,
            horizontalSpacing: 0,
            verticalSpacing: 0,
            fitContentWidth: true
        ) {
            Image(systemName: image)
            Text(" ")
            Text(name)
        }
        .foregroundColor(messageColor)
        .stroke(color: shadowColor, width: chat.shadowColorEnabled ? borderWidth : 0)
        .padding([.leading], 5)
        .font(.system(size: CGFloat(chat.fontSize)))
        .background(backgroundColor())
        .foregroundColor(.white)
        .cornerRadius(5)
    }
}
