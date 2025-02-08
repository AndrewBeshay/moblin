import UIKit

public enum ChatMessageRenderer {
    public static func attributedString(for message: ChatMessage, font: UIFont) async -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: message.text, attributes: [
            .font: font
        ])

        let downloadedEmotes = await downloadedEmotes(from: message).sorted(by: { lhs, rhs in
            lhs.range.lowerBound > rhs.range.lowerBound
        })

        downloadedEmotes.forEach { emote in
            let nsRange = NSRange(location: emote.range.lowerBound, length: emote.range.count)
            let emoteString = NSAttributedString(attachment: emote.textAttachment(font: font))
            attributedString.replaceCharacters(in: nsRange, with: emoteString)
        }

        return attributedString
    }

    private static func downloadedEmotes(from message: ChatMessage) async -> [DownloadedEmote] {
        return await withTaskGroup(of: Optional<DownloadedEmote>.self, returning: [DownloadedEmote].self, body: { group async -> [DownloadedEmote] in
            var downloadedEmotes = [DownloadedEmote]()

            for emote in message.emotes {
                group.addTask {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: emote.imageURL())
                        guard let image = UIImage(data: data) else { throw ChatMessageRenderError.corruptImageData }
                        return DownloadedEmote(image: image, range: emote.range)
                    } catch {
                        return nil
                    }
                }
            }

            for try await downloadedEmote in group {
                guard let downloadedEmote = downloadedEmote else { continue }
                downloadedEmotes.append(downloadedEmote)
            }

            return downloadedEmotes
        })
    }
}

enum ChatMessageRenderError: Error {
    case corruptImageData
}
