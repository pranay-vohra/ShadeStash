//
//  SavedCards.swift
//  ShadeStash
//
//  Created by pranay vohra on 13/08/25.
//

import Foundation
import SwiftData

@Model
class Card: Identifiable{
    var id: UUID
    var hexCode:String
    var colourName:String
    var date:Date
    
    
    
    init(id: UUID = UUID(), hexCode: String, colourName: String, date: Date = Date()) {
        self.id = id
        self.hexCode = hexCode
        self.colourName = colourName
        self.date = date
    }
}
