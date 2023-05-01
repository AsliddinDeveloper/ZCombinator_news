import LinkPresentation
import SwiftUI
import UniformTypeIdentifiers

struct StoryRow: View {
    let story: Story
    let url: URL?
    
    @EnvironmentObject var auth: Authentication
    
    @State private var isLoaded: Bool = false
    @State private var showSafari: Bool = false
    @State private var showHNSheet: Bool = false
    @State private var showReplySheet: Bool = false
    @State private var showFlagDialog: Bool = false
    @GestureState private var isDetectingPress = false
    @Binding private var showFlagToast: Bool
    @Binding private var showUpvoteToast: Bool
    
    init(story: Story, showFlagToast: Binding<Bool>, showUpvoteToast: Binding<Bool>) {
        self.story = story
        self.url = URL(string: story.url ?? "https://news.ycombinator.com/item?id=\(story.id)")
        self._showFlagToast = showFlagToast
        self._showUpvoteToast = showUpvoteToast
    }
    
    @ViewBuilder
    var navigationLink: some View {
        if story.isJobWithUrl {
            EmptyView()
        } else {
            NavigationLink(
                destination: {
                    ItemView<Story>(item: story)
                },
                label: {
                    EmptyView()
                })
        }
    }
    
    @ViewBuilder
    var menu: some View {
        Menu {
            Button {
                onUpvote()
            } label: {
                Label("Upvote", systemImage: "hand.thumbsup")
            }
            .disabled(!auth.loggedIn)
            Divider()
            Button {
                showFlagDialog = true
            } label: {
                Label("Flag", systemImage: "flag")
            }
            .disabled(!auth.loggedIn)
            Divider()
            Menu {
                if story.url.orEmpty.isNotEmpty {
                    Button {
                        showShareSheet(url: story.url.orEmpty)
                    } label: {
                        Text("Link to story")
                    }
                }
                Button {
                    showShareSheet(url: story.itemUrl)
                } label: {
                    Text("Link to HN")
                }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                showHNSheet = true
            } label: {
                Label("View on Hacker News", systemImage: "safari")
            }
        } label: {
            Label("", systemImage: "ellipsis")
                .padding(.leading)
                .padding(.bottom, 12)
                .foregroundColor(.orange)
        }
    }
    
    var body: some View {
        ZStack {
            navigationLink
            Button(
                action: {
                    if story.isJobWithUrl {
                        showSafari = true
                    }
                },
                label: {
                    HStack {
                        VStack {
                            Text(story.title.orEmpty)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .padding([.horizontal, .top])
                            Spacer()
                            HStack {
                                if let url = story.readableUrl {
                                    Text(url)
                                        .font(.footnote)
                                        .foregroundColor(.orange)
                                } else if let text = story.text {
                                    Text(text)
                                        .font(.footnote)
                                        .lineLimit(2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }.padding(.horizontal)
                            Divider().frame(maxWidth: .infinity)
                            HStack(alignment: .center) {
                                Text(story.metadata.orEmpty)
                                    .font(.caption)
                                    .padding(.top, 6)
                                    .padding(.leading)
                                    .padding(.bottom, 12)
                                Spacer()
                                menu
                            }
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                }
            )
            .if(.iOS16) { view in
                view
                    .contextMenu(
                        menuItems: {
                            Button {
                                showSafari = true
                            } label: {
                                Label("View in browser", systemImage: "safari")
                            }
                        },
                        preview: {
                            SafariView(url: url!)
                        })
            }
            .if(!.iOS16) { view in
                view
                    .contextMenu(
                        PreviewContextMenu(
                            destination: SafariView(url: url!),
                            actionProvider: { items in
                                return UIMenu(
                                    title: "",
                                    children: [
                                        UIAction(
                                            title: "View in browser",
                                            image: UIImage(systemName: "safari"),
                                            identifier: nil,
                                            handler: { _ in showSafari = true }
                                        )
                                    ])
                            }))
            }
        }
        .confirmationDialog("Are you sure?", isPresented: $showFlagDialog) {
            Button("Flag", role: .destructive) {
                onFlagTap()
            }
        } message: {
            Text("Flag \"\(story.title.orEmpty)\" by \(story.by.orEmpty)?")
        }
        .sheet(isPresented: $showHNSheet) {
            if let url = URL(string: story.itemUrl) {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showSafari) {
            if let urlStr = story.url, let url = URL(string: urlStr) {
                SafariView(url: url)
            }
        }
        
    }
    
    private func onUpvote() {
        Task {
            let res = await auth.upvote(story.id)
            
            if res {
                showUpvoteToast = true
                HapticFeedbackService.shared.success()
            } else {
                HapticFeedbackService.shared.error()
            }
        }
    }
    
    private func onFlagTap() {
        Task {
            let res = await AuthRepository.shared.flag(story.id)
            
            if res {
                showFlagToast = true
                HapticFeedbackService.shared.success()
            } else {
                HapticFeedbackService.shared.error()
            }
        }
    }
}
