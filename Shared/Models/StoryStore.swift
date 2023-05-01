import Foundation
import SwiftUI

extension HomeView {
    @MainActor
    class StoryStore: ObservableObject {
        @Published var storyType: StoryType = .top
        @Published var stories: [Story] = [Story]()
        @Published var status: Status = .idle
        
        private let pageSize: Int = 10
        private var currentPage: Int = 0
        private var storyIds: [Int] = [Int]()

        func fetchStories() async {
            withAnimation {
                self.stories = [Story]()
                self.status = .loading
            }
            self.currentPage = 0
            self.storyIds = await StoriesRepository.shared.fetchStoryIds(from: self.storyType)
  
            var stories = [Story]()
            
            await StoriesRepository.shared.fetchStories(ids: Array(storyIds[0..<10])) { story in
                stories.append(story)
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.status = .loaded
                    self.stories = stories
                }
            }
        }
        
        func refresh() async -> Void {
            await fetchStories()
        }
        
        func loadMore() async {
            if stories.count == storyIds.count {
                return
            }
            
            currentPage = currentPage + 1
            
            
            let startIndex = currentPage * pageSize
            let endIndex = min(startIndex + pageSize, storyIds.count)
            var stories = [Story]()
            
            await StoriesRepository.shared.fetchStories(ids: Array(storyIds[startIndex..<endIndex])) { story in
                stories.append(story)
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.status = .loaded
                    self.stories.append(contentsOf: stories)
                }
            }
        }
        
        func onStoryRowAppear(_ story: Story) {
            if let last = stories.last, last.id == story.id {
                Task {
                    await loadMore()
                }
            }
        }
    }
}
