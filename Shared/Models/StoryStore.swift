//
//  HomeView+ViewModel.swift
//  ZCombinator
//
//  Created by Jiaqi Feng on 7/27/22.
//

import Foundation
import SwiftUI

extension HomeView {
    @MainActor
    class StoryStore: ObservableObject {
        @Published var storyType: StoryType = .top
        @Published var stories: [Story] = [Story]()
        
        private let pageSize: Int = 10
        private var currentPage: Int = 0
        private var storyIds: [Int] = [Int]()
        
        func fetchStories() async {
            self.currentPage = 0
            self.stories = [Story]()
            self.storyIds = await StoriesRepository.shared.fetchStoryIds(from: self.storyType)
            
            var stories = [Story]()
            
            await StoriesRepository.shared.fetchStories(ids: Array(storyIds[0..<10])) { story in
                stories.append(story)
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.stories = stories
                }
            }
        }
        
        func refresh() {
            Task {
                await fetchStories()
            }
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
