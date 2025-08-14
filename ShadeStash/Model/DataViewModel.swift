//
//  DataViewModel.swift
//  ShadeStash
//
//  Created by pranay vohra on 13/08/25.
//


import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

@MainActor
class DataViewModel: ObservableObject{
    @Published var User = Users.empty
    let db = Firestore.firestore()
    
    func addColourCard(userId: String, card: Card) async throws {
        let userRef = db.collection("Users").document(userId)
    
        let firestoreCard = CardFirestore(from: card)
        
        do {
            try await userRef.setData([
                "savedColours": FieldValue.arrayUnion([try Firestore.Encoder().encode(firestoreCard)])
            ], merge: true)
            print("Card successfully added to user's saved colours")
        } catch {
            print("Error adding card: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteColourCard(userId: String, card: Card) async throws{
        let userRef = db.collection("Users").document(userId)
       
        let documentSnapshot = try await userRef.getDocument()
        
        guard let data = documentSnapshot.data(),
              let savedColours = data["savedColours"] as? [[String: Any]] else {
            print("No savedColours found for user")
            return
        }
        
        if let matchingCardDict = savedColours.first(where: { dict in
            if let id = dict["id"] as? String {
                return id == card.id.uuidString
            }
            return false
        }) {
            do {
               
                try await userRef.updateData([
                    "savedColours": FieldValue.arrayRemove([matchingCardDict])
                ])
                print("Card successfully removed from user's saved colours")
            } catch {
                print("Error removing card: \(error.localizedDescription)")
                throw error
            }
        } else {
            print("Matching card not found in savedColours")
            return
        }
    }
}
