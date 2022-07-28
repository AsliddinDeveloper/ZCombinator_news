//
//  ContentView.swift
//  Shared
//
//  Created by Jiaqi Feng on 7/18/22.
//

import SwiftUI
import CoreData

extension HomeView {
    @MainActor
    class HomeViewViewModel: ObservableObject {
        @Published var storyType: StoryType = .top
        @Published var stories: [Story] = [Story]()
        var currentPage: Int = 0
        
        private let pageSize: Int = 10
        private var storyIds: [Int] = [Int]()
        
        func fetchStories() async {
            self.currentPage = 0
            self.stories = [Story]()
            self.storyIds = await StoriesRepository.fetchStoryIds(from: self.storyType)
            
            var stories = [Story]()
            
            await StoriesRepository.fetchStories(ids: Array(storyIds[0..<10])) { story in
                stories.append(story)
            }
            
            DispatchQueue.main.async {
                self.stories = stories
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
            
            await StoriesRepository.fetchStories(ids: Array(storyIds[startIndex..<endIndex])) { story in
                stories.append(story)
            }
            
            DispatchQueue.main.async {
                self.stories.append(contentsOf: stories)
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

struct HomeView: View {
    @ObservedObject private var viewModel = HomeViewViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var isActive = false

    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.stories){ story in
                    ZStack {
                        StoryRow(story: story).listRowInsets(EdgeInsets()).onAppear {
                            viewModel.onStoryRowAppear(story)
                        }
                        NavigationLink(destination: ItemView(item: story), isActive: $isActive) {
                            EmptyView()
                        }.hidden()
                    }.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            isActive = true
                        } label: {
                            Label("Flag", systemImage: "flag")
                        }
                    }.listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                }
            }
            .listStyle(.plain)
            .refreshable {
                viewModel.refresh()
            }
            .toolbar {
//#if os(iOS)
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//#endif
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
                ToolbarItem{
                    Menu {
                        ForEach(StoryType.allCases, id: \.self) { storyType in
                            Button("\(storyType.rawValue.uppercased())") {
                                viewModel.storyType = storyType
                            
                                Task {
                                    await viewModel.fetchStories()
                                }
                            
                            }
                        }
                    } label: {
                        Label("Add Item", systemImage: "list.bullet")
                    }
                }
            }
            .navigationTitle(viewModel.storyType.rawValue.uppercased())
            Text("Select an item")
        }.task {
            await viewModel.fetchStories()
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
