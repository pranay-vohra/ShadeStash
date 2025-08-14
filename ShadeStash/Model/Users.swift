//
//  User.swift
//  ShadeStash
//
//  Created by pranay vohra on 12/08/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift


struct Users: Identifiable,Codable{
    @DocumentID var id:String? 
    var savedColours:[CardFirestore]
    
    init(id: String? = nil, savedColours: [CardFirestore] = []) {
        self.id = id
        self.savedColours = savedColours
    }
}

extension Users{
    static var empty: Users {
        Users(savedColours: [CardFirestore(from:Card(hexCode: "", colourName: "", date:Date()))])
    }
}
