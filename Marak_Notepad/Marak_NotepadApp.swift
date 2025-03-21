//
//  Marak_NotepadApp.swift
//  Marak_Notepad
//
//  Created by Nipun on 21/3/25.
//

import SwiftUI
import SwiftData

@main
struct MarakNotepadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Task.self, Category.self])
    }
}
