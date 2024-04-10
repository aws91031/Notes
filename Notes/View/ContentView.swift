//
//  ContentView.swift
//  Notes
//
//  Created by user250993 on 4/3/24.
//

import SwiftUI
import Firebase

struct ContentView: View {
    
    @AppStorage("log_status") private var logStatus: Bool = false
    
    var body: some View {
        if logStatus {
            NoteView()
        } else {
            Login()
        }
    }
}

#Preview {
    ContentView()
}
