//
//  BorderedViewModifier.swift
//  badgemagic
//
//  Created by Siddharth sen on 12/23/19.
//  Copyright © 2019 Aditya Gupta. All rights reserved.
//

import SwiftUI


///Retruns the same view the modifier is applied to
struct BorderedViewModifier: ViewModifier {
    func body(content:Content) -> some View{
        content
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)).background(Color.white).overlay(
        
        RoundedRectangle(cornerRadius: 8)
        .stroke(lineWidth: 2)
            .foregroundColor(.blue)
        ).cornerRadius(8)
        .shadow(color: Color.gray.opacity(0.4), radius: 3, x: 1, y: 2)
    }
}
