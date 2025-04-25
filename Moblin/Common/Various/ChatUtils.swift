import Foundation

extension String {
    func makeChatPostTextSegments(id: inout Int) -> [ChatPostSegment] {
        var segments: [ChatPostSegment] = []
        for word in split(separator: " ") {
            segments.append(ChatPostSegment(
                id: id,
                text: "\(word) "
            ))
            id += 1
        }
        return segments
    }
    
    func makeChatPostTextSegments(text: String, id: inout Int) -> [ChatPostSegment] {
        var segments: [ChatPostSegment] = []
        for word in text.split(separator: " ") {
            segments.append(ChatPostSegment(
                id: id,
                text: "\(word) "
            ))
            id += 1
        }
        return segments
    }
}
