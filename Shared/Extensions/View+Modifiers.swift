//
//  View+Modifiers.swift
//  ZCombinator
//
//  Created by Jiaqi Feng on 8/4/22.
//

import Foundation
import SwiftUI

struct BorderedFootnote: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(4)
    }
}

extension View {
    func borderedFootnote() -> some View {
        modifier(BorderedFootnote())
    }
}
