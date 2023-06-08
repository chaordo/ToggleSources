//
//  NewsTabView.swift
//  XCANews
//
//  Created by Alfian Losari on 6/27/21.
//

import SwiftUI

struct NewsTabView: View {
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @StateObject var articleNewsVM: ArticleNewsViewModel
    
    init(articles: [Article]? = nil, category: Category = .general) {
        self._articleNewsVM = StateObject(wrappedValue: ArticleNewsViewModel(articles: articles, selectedCategory: category))
    }
    
    var body: some View {
        ArticleListView(articles: articleNewsVM.articles, isFetchingNextPage: articleNewsVM.isFetchingNextPage, nextPageHandler: { await articleNewsVM.loadNextPage() })
            .overlay(overlayView)
            .task(id: articleNewsVM.fetchTaskToken, loadTask)
            .refreshable(action: refreshTask)
            //.navigationTitle(articleNewsVM.fetchTaskToken.category.text)
            #if os(iOS)
            .navigationBarItems(trailing: navigationBarItem)
            #elseif os(macOS)
            .navigationSubtitle(articleNewsVM.lastRefreshedDateText)
            .focusedSceneValue(\.refreshAction, refreshTask)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: refreshTask) {
                        Image(systemName: "arrow.clockwise")
                            .imageScale(.large)
                    }
                }
            }
            #endif
    }
    
    @ViewBuilder
    private var overlayView: some View {
        
        switch articleNewsVM.phase {
        case .empty:
            ProgressView()
        case .success(let articles) where articles.isEmpty:
            EmptyPlaceholderView(text: "No Articles", image: nil)
        case .failure(let error):
            RetryView(text: error.localizedDescription, retryAction: refreshTask)
        default: EmptyView()
        }
    }
    
    @Sendable
    private func loadTask() async {
        await articleNewsVM.loadFirstPage()
    }
    
    @Sendable
    private func refreshTask() {
        Task {
            await articleNewsVM.refreshTask()
        }
    }
    
    #if os(iOS)
    @State private var isShowingMenu = false
    @State private var isAxiosSelected = false
    @State private var isBloombergSelected = false

    private var navigationBarItem: some View {
        Button("Sources") {
            isShowingMenu = true
        }
        .sheet(isPresented: $isShowingMenu) {
            VStack {
                HStack {
                    Button(action: {
                        isAxiosSelected.toggle()
                    }) {
                        Text("Axios")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isAxiosSelected ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .opacity(isAxiosSelected ? 1 : 0)
                            )
                    }
                    .buttonStyle(ToggleButtonStyle())
                    
                    Button(action: {
                        isBloombergSelected.toggle()
                    }) {
                        Text("Bloomberg")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isBloombergSelected ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .opacity(isBloombergSelected ? 1 : 0)
                            )
                    }
                    .buttonStyle(ToggleButtonStyle())
                }
                
                Button("Apply") {
                    var selectedCategories: [Category] = []
                    
                    if isAxiosSelected {
                        selectedCategories.append(.Axios)
                    }
                    
                    if isBloombergSelected {
                        selectedCategories.append(.Bloomberg)
                    }
                    
                    articleNewsVM.fetchTaskToken.category = selectedCategories
                    isShowingMenu = false
                }
            }
        }
    }

    struct ToggleButtonStyle: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
        }
    }
    #endif
}

struct NewsTabView_Previews: PreviewProvider {
    
    @StateObject static var articleBookmarkVM = ArticleBookmarkViewModel.shared

    
    static var previews: some View {
        NewsTabView(articles: Article.previewData)
            .environmentObject(articleBookmarkVM)
    }
}
