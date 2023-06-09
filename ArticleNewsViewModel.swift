//
//  ArticleNewsViewModel.swift
//  XCANews
//
//  Created by Alfian Losari on 6/27/21.
//

import SwiftUI

struct FetchTaskToken: Equatable {
    var category: [Category]
    var token: Date
}

fileprivate let dateFormatter = DateFormatter()

@MainActor
class ArticleNewsViewModel: ObservableObject {
    
    @Published var phase = DataFetchPhase<[Article]>.empty
    @Published var fetchTaskToken: FetchTaskToken {
        didSet {
            if #available(iOS 16.0, *) {
                if !fetchTaskToken.category.isEmpty && !fetchTaskToken.category.contains(oldValue.category) {
                    selectedMenuItemId = MenuItem.category(fetchTaskToken.category.first!).id
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    @AppStorage("item_selection") private var selectedMenuItemId: MenuItem.ID?

    private let newsAPI = NewsAPI.shared
    private let pagingData = PagingData(itemsPerPage: 10, maxPageLimit: 5)
    
    // Currently only the In-Memory Cache will work for Pagination flow as the DiskCache is not persisting the Paging Data to disk. Data won't be able to restored after app restarts.
    private let cache = InMemoryCache<[Article]>(expirationInterval: 5 * 60)

    var lastRefreshedDateText: String {
        dateFormatter.timeStyle = .short
        return "Last refreshed at: \(dateFormatter.string(from: fetchTaskToken.token))"
    }
    
    var articles: [Article] {
        phase.value ?? []
    }
    
    var isFetchingNextPage: Bool {
        if case .fetchingNextPage = phase {
            return true
        }
        return false
    }
    
    init(articles: [Article]? = nil, selectedCategory: Category = .general) {
        if let articles = articles {
            self.phase = .success(articles)
        } else {
            self.phase = .empty
        }
        self.fetchTaskToken = FetchTaskToken(category: [selectedCategory], token: Date())
    }
    
    func refreshTask() async {
        for category in fetchTaskToken.category {
            await cache.removeValue(forKey: category.rawValue)
        }

        fetchTaskToken.token = Date()
    }
    
    func loadFirstPage() async {
            if Task.isCancelled { return }
            let category = fetchTaskToken.category
            if let articles = await cache.value(forKey: String(describing: category)) {
                await print("PAGING: From Cache, Current Page \(pagingData.currentPage), maxPageLimit: \(pagingData.maxPageLimit)")
                phase = .success(articles)
                return
            }
                    
            phase = .empty
            do {
                await pagingData.reset()
                
                let articles = try await pagingData.loadNextPage(dataFetchProvider: loadArticles(page:))
                await cache.setValue(articles, forKey: String(describing: category))
                
                if Task.isCancelled { return }
                phase = .success(articles)
            } catch {
                if Task.isCancelled { return }
                print(error.localizedDescription)
                phase = .failure(error)
            }
        }
    
    func loadNextPage() async {
        if Task.isCancelled { return }
        
        var articles = self.phase.value ?? []
        phase = .fetchingNextPage(articles)
        
        do {
            let nextArticles = try await pagingData.loadNextPage(dataFetchProvider: loadArticles(page:))
            if Task.isCancelled { return }
            
            articles += nextArticles
            
            let categoryRawValues = fetchTaskToken.category.map { $0.rawValue }
            let categoryRawValue = categoryRawValues.joined(separator: ",")
            await cache.setValue(articles, forKey: categoryRawValue)
            
            phase = .success(articles)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func loadArticles(page: Int) async throws -> [Article] {
        let categories = fetchTaskToken.category
        var allArticles: [Article] = []
        
        for category in categories {
            let articles = try await newsAPI.fetch(
                from: category,
                page: page,
                pageSize: pagingData.itemsPerPage
            )
            if Task.isCancelled { return [] }
            allArticles.append(contentsOf: articles)
        }
        
        return allArticles
    }
}
