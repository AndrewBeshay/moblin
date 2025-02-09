//
//  SystemMessageView.swift
//  Moblin
//
//  Created by Andrew Beshay on 10/2/2025.
//

import SwiftUI

/// A view that displays a system message, such as a notification that a user's message was deleted.
/// This view can be used for various system notifications (e.g. "User X's message was deleted by Moderator Y").
struct SystemView: View {
    var chat: SettingsChat

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
    /// The username related to the system event (for example, the user whose message was deleted).
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            // Combine the components of the system message.
            Text("\(text)")
                .font(.system(size: CGFloat(chat.fontSize)))
                .foregroundColor(.gray)
                .lineLimit(nil)
        }
        .padding([.leading], 5)
        .background(backgroundColor())
        .cornerRadius(5)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
