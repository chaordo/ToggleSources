//
//  SourcesView.swift
//  XCANews
//
//  Created by John on 6/7/23.
//
/*
import SwiftUI

struct SourcesView: View {
    
    private var navigationBarItem: some View {
        
        init(articles: [Article]? = nil, category: Category = .general) {
            self._articleNewsVM = StateObject(wrappedValue: ArticleNewsViewModel(articles: articles, selectedCategory: category))
        }
        
        var body: some View {
            NavigationView {
                List {
                    VStack {
                        HStack {
                            ForEach(Category.allCases) { category in
                                Button(action: {
                                    self.articleNewsVM.fetchTaskToken.category = category
                                }) {
                                    Text(category.text)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(self.articleNewsVM.fetchTaskToken.category == category ? Color.blue : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
*/
