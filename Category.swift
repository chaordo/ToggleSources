//
//  Category.swift
//  XCANews
//
//  Created by Alfian Losari on 6/27/21.
//

import Foundation

enum Category: String, CaseIterable, Codable {
    case general
    case Axios
    case Bloomberg
    
    var text: String {
        if self == .general {
            return "Top Headlines"
        }
        return rawValue.capitalized
    }
    
    var systemImage: String {
        switch self {
        case .general:
            return "newspaper"
        case .Axios:
            return "building.2"
        case .Bloomberg:
            return "desktopcomputer"
        }
    }
    
    var sortIndex: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

extension Category: Identifiable {
    var id: Self { self }
}
