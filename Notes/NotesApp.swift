//
//  NotesApp.swift
//  Notes
//
//  Created by user250993 on 4/3/24.
//

import SwiftUI
import Firebase

@main
struct NotesApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
