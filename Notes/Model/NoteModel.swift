//
//  NoteModel.swift
//  Notes
//
//  Created by user250993 on 4/3/24.
//

import Foundation
import FirebaseFirestoreSwift

struct NoteModel : Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var notesdata: String
}
