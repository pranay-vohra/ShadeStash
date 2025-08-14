//
//  homeViewModel.swift
//  ShadeStash
//
//  Created by pranay vohra on 14/08/25.
//

import Foundation
import SwiftUI
import SwiftData
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var firestoreCards: [Card] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var sortOption: SortOption = .dateDesc
    @Published var showAddSheet = false
    @Published var isPressed = false
    
    private var firestoreListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    enum SortOption {
        case dateAsc, dateDesc, nameAsc, nameDesc
    }
    
    // MARK: - Computed Properties
    
    func getDisplayCards(localCards: [Card], isConnected: Bool) -> [Card] {
        isConnected ? firestoreCards : localCards
    }
    
    func getFilteredCards(displayCards: [Card]) -> [Card] {
        let filtered = displayCards.filter { card in
            searchText.isEmpty || card.colourName.lowercased().contains(searchText.lowercased())
        }
        
        switch sortOption {
        case .dateAsc:
            return filtered.sorted { $0.date < $1.date }
        case .dateDesc:
            return filtered.sorted { $0.date > $1.date }
        case .nameAsc:
            return filtered.sorted { $0.colourName.lowercased() < $1.colourName.lowercased() }
        case .nameDesc:
            return filtered.sorted { $0.colourName.lowercased() > $1.colourName.lowercased() }
        }
    }
    
    // MARK: - Firestore Real-time Listener
    
    func setupRealtimeListener(userId: String?, isConnected: Bool) {
        guard let userId = userId, isConnected else {
            removeRealtimeListener()
            return
        }
        
        // Check if listener is already set up for this user
        if currentUserId == userId && firestoreListener != nil {
            return
        }
        
        // Remove existing listener
        removeRealtimeListener()
        currentUserId = userId
        
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userId)
        
        isLoading = true
        
        firestoreListener = userRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                defer { self.isLoading = false }
                
                if let error = error {
                    print("Error listening to user document: \(error)")
                    return
                }
                
                guard let document = documentSnapshot else {
                    print("No document snapshot received")
                    self.firestoreCards = []
                    return
                }
                
                if !document.exists {
                    print("User document does not exist")
                    self.firestoreCards = []
                    return
                }
                
                do {
                    if let user = try document.data(as: Users?.self) {
                        // Convert CardFirestore to Card safely
                        let cards = user.savedColours.compactMap { firestoreCard -> Card? in
                            // Validate card data before creating Card object
                            guard !firestoreCard.hexCode.isEmpty,
                                  !firestoreCard.colourName.isEmpty else {
                                print("Invalid card data: \(firestoreCard)")
                                return nil
                            }
                            
                            return Card(
                                id: firestoreCard.id,
                                hexCode: firestoreCard.hexCode,
                                colourName: firestoreCard.colourName,
                                date: firestoreCard.date
                            )
                        }
                        
                        self.firestoreCards = cards
                        print("Fetched \(self.firestoreCards.count) cards from Firestore")
                    } else {
                        self.firestoreCards = []
                    }
                } catch {
                    print("Error decoding user document: \(error)")
                    self.firestoreCards = []
                }
            }
        }
    }
    
    func removeRealtimeListener() {
        firestoreListener?.remove()
        firestoreListener = nil
        currentUserId = nil
    }
    
    // MARK: - Local Storage Sync
    
    func syncToLocalStorage(context: ModelContext, localCards: [Card]) {
        do {
            // Clear existing local cards
            for localCard in localCards {
                context.delete(localCard)
            }
            
            // Add Firestore cards to local storage
            for firestoreCard in firestoreCards {
                let localCard = Card(
                    id: firestoreCard.id,
                    hexCode: firestoreCard.hexCode,
                    colourName: firestoreCard.colourName,
                    date: firestoreCard.date
                )
                context.insert(localCard)
            }
            
            // Save context
            try context.save()
            print("Synced \(firestoreCards.count) cards to local storage")
        } catch {
            print("Error syncing to local storage: \(error)")
        }
    }
    
    // MARK: - UI Actions
    
    func showAddCardSheet() {
        withAnimation(.spring()) {
            showAddSheet.toggle()
        }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func handleButtonPress(_ pressing: Bool) {
        withAnimation(.easeInOut(duration: 0.12)) {
            isPressed = pressing
        }
    }
    
    func setSortOption(_ option: SortOption) {
        sortOption = option
    }
    
    // MARK: - Lifecycle
    
    func handleNetworkChange(isConnected: Bool, userId: String?) {
        print("Network status changed: \(isConnected ? "Online" : "Offline")")
        
        if isConnected && userId != nil {
            print("Setting up Firestore listener due to network reconnection")
            setupRealtimeListener(userId: userId, isConnected: isConnected)
        } else {
            print("Removing Firestore listener due to network disconnection")
            removeRealtimeListener()
            // Don't clear firestoreCards here - keep them for when we go back online
        }
    }
    
    func handleUserChange(userId: String?, isConnected: Bool) {
        print("User changed: \(userId ?? "nil")")
        
        if let userId = userId {
            setupRealtimeListener(userId: userId, isConnected: isConnected)
        } else {
            removeRealtimeListener()
            firestoreCards = []
        }
    }
    
    // Clean up resources
    func cleanup() {
        removeRealtimeListener()
        cancellables.removeAll()
        firestoreCards = []
    }
    
    deinit {
        // Don't use Task in deinit, just clean up directly
        firestoreListener?.remove()
        cancellables.removeAll()
    }
}
