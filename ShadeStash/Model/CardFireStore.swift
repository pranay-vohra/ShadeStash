//
//  CardFireStore.swift
//  ShadeStash
//
//  Created by pranay vohra on 14/08/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct CardFirestore: Identifiable, Codable {
    var id: UUID
    var hexCode: String
    var colourName: String
    var date: Date

    init(from card: Card) {
        self.id = card.id
        self.hexCode = card.hexCode
        self.colourName = card.colourName
        self.date = card.date
    }

    func toSwiftDataCard() -> Card {
        return Card(id: self.id, hexCode: self.hexCode, colourName: self.colourName, date: self.date)
    }
}
