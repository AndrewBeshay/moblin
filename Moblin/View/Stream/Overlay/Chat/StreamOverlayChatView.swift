import Collections
import SDWebImageSwiftUI
import SwiftUI
import WrappingHStack

private let borderWidth: CGFloat = 1.5

struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct StreamOverlayChatView: View {
    @EnvironmentObject var model: Model
    private let spaceName = "scroll"
    @State private var wholeSize: CGSize = .zero
    @State private var scrollViewSize: CGSize = .zero
    @State private var previousOffset: CGFloat = 0.0

    // MARK: - Computed Properties for Transformations

    private var rotation: Double {
        (model.database.chat.newMessagesAtTop ?? true) ? 0.0 : 180.0
    }
    
    private var scaleX: Double {
        (model.database.chat.newMessagesAtTop ?? true) ? 1.0 : -1.0
    }
    
    private var mirrorMultiplier: CGFloat {
        (model.database.chat.mirrored ?? false) ? -1 : 1
    }
    
    // Determines if the scroll offset is near the "start" of the chat.
    private func isCloseToStart(offset: CGFloat) -> Bool {
        if model.database.chat.newMessagesAtTop ?? true {
            return offset < 50
        } else {
            return offset >= scrollViewSize.height - wholeSize.height - 50.0
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { metrics in
            VStack {
                Spacer()
                ChildSizeReader(size: $wholeSize) {
                    ScrollView(showsIndicators: false) {
                        ChildSizeReader(size: $scrollViewSize) {
                            chatPostsContent
                        }
                    }
                    .foregroundColor(.white)
                    .rotationEffect(Angle(degrees: rotation))
                    .scaleEffect(x: scaleX * Double(mirrorMultiplier), y: 1.0, anchor: .center)
                    .coordinateSpace(name: spaceName)
                    .frame(
                        width: metrics.size.width * (model.database.chat.width ?? 1.0),
                        height: metrics.size.height * (model.database.chat.height ?? 1.0)
                    )
                }
            }
        }
    }
    
    // MARK: - Extracted Subviews and Helpers
        
    // The content view that displays all chat posts.
    private var chatPostsContent: some View {
        VStack {
            LazyVStack(alignment: .leading, spacing: 1) {
                // Convert model.chatPosts (a Deque) to an Array to avoid binding initializer issues.
                ForEach(Array(model.chatPosts)) { post in
                    postView(for: post)
                }
            }
            Spacer(minLength: 0)
        }
        .background(chatPostsBackground)
        .onPreferenceChange(ViewOffsetKey.self) { offset in
            let clampedOffset = max(offset, 0)
            handleScrollOffsetChange(clampedOffset)
        }
        .frame(minHeight: scrollViewSize.height)
    }
    
    // A background view that tracks the vertical offset using a GeometryReader.
    private var chatPostsBackground: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ViewOffsetKey.self,
                value: -proxy.frame(in: .named(spaceName)).origin.y
            )
        }
    }
    
    // Returns a view for a single chat post.
    private func postView(for post: ChatPost) -> some View {
        Group {
            if post.user != nil {
                if let highlight = post.highlight {
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 3)
                            .foregroundColor(highlight.color)
                        VStack(alignment: .leading, spacing: 1) {
                            HighlightMessageView(
                                chat: model.database.chat,
                                image: highlight.image,
                                name: highlight.title
                            )
                            LineView(
                                post: post,
                                chat: model.database.chat
                            )
                        }
                    }
                    .modifier(RotationAndScaleModifier(rotation: rotation, scaleX: scaleX))
                } else {
                    LineView(post: post, chat: model.database.chat)
                        .padding(.leading, 3)
                        .modifier(RotationAndScaleModifier(rotation: rotation, scaleX: scaleX))
                }
            } else {
                // When there is no user, display a red divider.
                Rectangle()
                    .fill(Color.red)
                    .frame(width: UIScreen.main.bounds.width, height: 1.5)
                    .padding(2)
                    .modifier(RotationAndScaleModifier(rotation: rotation, scaleX: scaleX))
            }
        }
    }
    
    // Handles scroll offset changes to pause or resume chat updates.
    private func handleScrollOffsetChange(_ offset: CGFloat) {
        if isCloseToStart(offset: offset) {
            if model.chatPaused, offset >= previousOffset {
                model.endOfChatReachedWhenPaused()
            }
        } else if !model.chatPaused, !model.chatPosts.isEmpty {
            model.pauseChat()
        }
        previousOffset = offset
    }
}

// MARK: - Rotation and Scale Modifier

/// A custom view modifier that applies rotation and horizontal scaling.
struct RotationAndScaleModifier: ViewModifier {
    let rotation: Double
    let scaleX: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: rotation))
            .scaleEffect(x: scaleX, y: 1.0, anchor: .center)
    }
}
