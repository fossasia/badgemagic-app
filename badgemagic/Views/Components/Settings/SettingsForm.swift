//
//  SettingsForm.swift
//  badgemagic
//
//  Created by Siddharth sen on 12/23/19.
//  Copyright © 2019 Aditya Gupta. All rights reserved.
//

import SwiftUI
import Foundation

struct SettingsForm: View {
    @State var selectedLanguage: Int = 0
    @Environment(\.presentationMode) var presentationMode

    func debugInfoView(title: String, info: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(info).font(.body).foregroundColor(.secondary)
        }
    }

    var region: [String] {
        var region: [String] = []
        for code in NSLocale.isoCountryCodes {
            let regionId = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_US")
                .displayName(forKey: NSLocale.Key.identifier, value: regionId)!
            region.append(name)
        }
        return region
    }

    var language: [String] {
        return ["English", "Japanese"]
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Language preferences"),
                    content: {
                        Picker(selection: $selectedLanguage,
                            label: Text("Language"),
                            content: {
                                ForEach(0 ..< self.language.count) {
                                    Text(self.language[$0]).tag($0)
                                }
                            })
                    })
                Section(header: Text("Region preferences"),
                    content: {
                        Picker(selection: $selectedLanguage,
                            label: Text("Region"),
                            content: {
                                ForEach(0 ..< self.region.count) {
                                    Text(self.region[$0]).tag($0)
                                }
                            })
                    })

            }
                .onAppear {

                }
                .navigationBarItems(
                    leading: Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                            Text("Cancel").foregroundColor(.red)
                        }),
                    trailing: Button(action: { }, label: {
                            Text("Save")
                        }))
                .navigationBarTitle(Text("Settings"))
        }
    }
}

#if DEBUG
    struct SettingsForm_Previews: PreviewProvider {
        static var previews: some View {
            SettingsForm()
        }
    }
#endif
