import UIKit

struct DownloadedEmote {
    init(image: UIImage, range: ClosedRange<Int>) {
        self.image = image
        self.range = range
    }

    func textAttachment(font: UIFont) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = image
        // Calculate the bounds based on font size and descender for alignment
        attachment.bounds = CGRect(origin: CGPoint(x: 0, y: font.descender), size: CGSize(width: 22, height: 22))
        return attachment
    }

    private let image: UIImage
    let range: ClosedRange<Int>
}
