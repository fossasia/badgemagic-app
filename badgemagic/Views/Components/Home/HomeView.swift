//
//  HomeView.swift
//  badgemagic
//
//  Created by Siddharth sen on 12/23/19.
//  Copyright © 2019 Aditya Gupta. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @State private var isSettingPresented = false
    @State var input:String = ""
    
    
    @ObservedObject var keyboardHandler: KeyboardFollower

    init(keyboardHandler: KeyboardFollower) {
      self.keyboardHandler = keyboardHandler
    }
    
    
    private var drawButton: some View {
       Button(action: {
           //draw Badges
        print("drawButton Pressed")
       }) {
           HStack {
               Image(systemName: "pencil.and.outline").imageScale(.medium)
           }.frame(width: 30, height: 30)
       }
       }

    private var savedButton: some View {
    Button(action: {
        //Saves Badges and Saved Cliparts
        print("savedButton Pressed")
    }) {
        HStack {
            Image(systemName: "tray.full").imageScale(.medium)
        }.frame(width: 30, height: 30)
    }
    }
    
    private var settingButton: some View {
    Button(action: {
        self.isSettingPresented = true
    }) {
        HStack {
            Image(systemName: "wrench").imageScale(.medium)
        }.frame(width: 30, height: 30)
    }
    }
    
    var body: some View {
       
        let view = Group {
            HStack {
                Spacer()
                
                ModifiedContent(content:TextField("Enter Text",text:$input).padding(8) , modifier: BorderedViewModifier())
                Spacer(minLength: 16)
            }.padding(32)
            
            HStack {
                Button(action: {}){
                    Text("Transfer")
                }
            }
            
            
        }
        .navigationBarItems(trailing:
            HStack {
                drawButton
                savedButton
                settingButton
            }
        ).sheet(isPresented: $isSettingPresented,
                content: { SettingsForm() })
        
        return navigationView(content: AnyView(view))
    }


    private func navigationView(content: AnyView) -> some View {
        Group {
            
                NavigationView {
                    content
                }.navigationViewStyle(DoubleColumnNavigationViewStyle())
            
            }
        }
    }



    



struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(keyboardHandler: KeyboardFollower())
    }
}

