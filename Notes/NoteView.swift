//
//  NoteView.swift
//  Notes
//
//  Created by user250993 on 4/3/24.
//

import SwiftUI
import Firebase

struct NoteView: View {
    @AppStorage("log_status") private var logStatus: Bool = false
    @ObservedObject var noteApp = NoteViewModel()
    @State var note = NoteModel(title: "", notesdata: "")
    // @State
    // @ObservedObject
    // @StateObject
    
    var body: some View {
        NavigationStack {
            List {
                ForEach($noteApp.notes) { $note in
                    NavigationLink {
                        NoteDetail(note: $note)
                    } label: {
                        Text(note.title)
                    }
                }
                Section {
                    NavigationLink {
                        NoteDetail(note: $note)
                    } label: {
                        Text("New note")
                            .foregroundColor(Color.gray)
                            .font(.system(size: 15))
                    }
                }
            }
            .onAppear {
                noteApp.fetchData()
            }
            Button("Logout") {
                try? Auth.auth().signOut()
                logStatus = false
            }
        }
        .refreshable {
            noteApp.fetchData()
        }
        
    }
}

#Preview {
    NoteView()
}
