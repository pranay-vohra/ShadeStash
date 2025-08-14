//
//  HomeUIView.swift
//  ShadeStash
//
//  Created by pranay vohra on 12/08/25.
//

import SwiftUI
import SwiftData

struct HomeUIView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.modelContext) var context
    @StateObject var dataViewModel = DataViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    
    // SwiftData cards (offline fallback)
    @Query(sort: \Card.date) var localCards: [Card]
    
    // Computed properties using ViewModel
    private var displayCards: [Card] {
        homeViewModel.getDisplayCards(
            localCards: localCards,
            isConnected: networkMonitor.isConnected
        )
    }
    
    private var filteredCards: [Card] {
        homeViewModel.getFilteredCards(displayCards: displayCards)
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Custom header
                headerView
                
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        // Search Bar
                        searchBarView
                        
                        // Cards Display
                        cardsDisplayView
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .overlay(addButtonOverlay, alignment: .bottomTrailing)
            .sheet(isPresented: $homeViewModel.showAddSheet) {
                AddColourCardUIView()
            }
        }
        .onAppear {
            setupViewModel()
        }
        .onDisappear {
            homeViewModel.removeRealtimeListener()
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            handleNetworkChange(isConnected: isConnected)
        }
        .onChange(of: authViewModel.user?.uid) { _, userId in
            handleUserChange(userId: userId)
        }
        .onChange(of: homeViewModel.firestoreCards) { _, _ in
            handleFirestoreCardsChange()
        }
    }
    
    // MARK: - Event Handlers
    
    private func setupViewModel() {
        print("Setting up ViewModel - User: \(authViewModel.user?.uid ?? "nil"), Connected: \(networkMonitor.isConnected)")
        homeViewModel.setupRealtimeListener(
            userId: authViewModel.user?.uid,
            isConnected: networkMonitor.isConnected
        )
    }
    
    private func handleNetworkChange(isConnected: Bool) {
        print("Network change detected: \(isConnected ? "Online" : "Offline")")
        
        homeViewModel.handleNetworkChange(
            isConnected: isConnected,
            userId: authViewModel.user?.uid
        )
        
        // Sync when coming online and we have Firestore data
        if isConnected && !homeViewModel.firestoreCards.isEmpty {
            print("Syncing Firestore data to local storage")
            homeViewModel.syncToLocalStorage(
                context: context,
                localCards: localCards
            )
        }
    }
    
    private func handleUserChange(userId: String?) {
        print("User change detected: \(userId ?? "nil")")
        homeViewModel.handleUserChange(
            userId: userId,
            isConnected: networkMonitor.isConnected
        )
    }
    
    private func handleFirestoreCardsChange() {
        print("Firestore cards changed: \(homeViewModel.firestoreCards.count) cards")
        // Auto-sync when Firestore data changes and we're connected
        if networkMonitor.isConnected {
            homeViewModel.syncToLocalStorage(
                context: context,
                localCards: localCards
            )
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(authViewModel.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text("Welcome To ShadeStash")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    // Online/Offline indicator with animation
                    HStack(spacing: 2) {
                        Circle()
                            .fill(networkMonitor.isConnected ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
                        
                        Text(networkMonitor.isConnected ? "Online" : "Offline")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(networkMonitor.isConnected ? .green : .orange)
                            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.systemBackground))
            
            Spacer()
            
            // Loading indicator
            if homeViewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.trailing, 8)
            }
            
            // User profile navigation
            userProfileButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - User Profile Button
    
    private var userProfileButton: some View {
        NavigationLink {
            Form {
                Section("Data Information") {
                    HStack {
                        Text("Total Cards")
                        Spacer()
                        Text("\(displayCards.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            homeViewModel.cleanup() // Clean up before signing out
                            authViewModel.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle("User Profile")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            ZStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 42, height: 42)
                    .foregroundStyle(.black)
                
                // Network status dot
                Circle()
                    .fill(networkMonitor.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 15, y: 15)
                    .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
            }
        }
    }
    
    // MARK: - Search Bar View
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: $homeViewModel.searchText)
                .foregroundColor(.primary)
            
            Spacer(minLength: 0)
            
            sortMenuView
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color(UIColor.systemGray6)))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Sort Menu View
    
    private var sortMenuView: some View {
        Menu {
            Button {
                homeViewModel.setSortOption(.dateAsc)
            } label: {
                Label("Date ↑", systemImage: homeViewModel.sortOption == .dateAsc ? "checkmark" : "")
            }
            
            Button {
                homeViewModel.setSortOption(.dateDesc)
            } label: {
                Label("Date ↓", systemImage: homeViewModel.sortOption == .dateDesc ? "checkmark" : "")
            }
            
            Button {
                homeViewModel.setSortOption(.nameAsc)
            } label: {
                Label("Name A→Z", systemImage: homeViewModel.sortOption == .nameAsc ? "checkmark" : "")
            }
            
            Button {
                homeViewModel.setSortOption(.nameDesc)
            } label: {
                Label("Name Z→A", systemImage: homeViewModel.sortOption == .nameDesc ? "checkmark" : "")
            }
        } label: {
            Image(systemName: "line.horizontal.3.decrease")
                .foregroundColor(.white)
                .frame(width: 30, height: 10)
                .padding(8)
                .background(Capsule().fill(Color.black))
        }
    }
    
    // MARK: - Cards Display View
    
    private var cardsDisplayView: some View {
        VStack {
            if displayCards.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredCards) { card in
                    ViewCardUI(
                        hexCode: card.hexCode,
                        colourName: card.colourName,
                        ignoreAI: false
                    )
                    .contextMenu {
                        if(networkMonitor.isConnected){
                            Button(role: .destructive) {
                                deleteCard(card)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Card Function
    
    private func deleteCard(_ card: Card) {
        guard let userId = authViewModel.user?.uid else {
            print("No user ID available for deletion")
            return
        }
        
        Task {
            do {
                // Always try to delete from Firestore if connected
                // The realtime listener will handle updating the UI
                try await dataViewModel.deleteColourCard(userId: userId, card: card)
                print("Card deleted successfully")
            } catch {
                print("Delete failed: \(error)")
                // Handle error appropriately - maybe show an alert
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            networkMonitor.isConnected ? "No cards in cloud" : "No cards offline",
            systemImage: "square.on.square",
            description: Text(networkMonitor.isConnected ?
                "Add a card to sync to cloud." :
                "Cards will sync when back online.")
        )
        .offset(y: 100)
    }
    
    // MARK: - Add Button Overlay
    
    private var addButtonOverlay: some View {
        Button {
            homeViewModel.showAddCardSheet()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color(red: 203/255, green: 136/255, blue: 169/255))
                )
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
        }
        .disabled(!networkMonitor.isConnected)
        .padding(16)
        .scaleEffect(homeViewModel.isPressed ? 0.95 : 1.0)
        .onLongPressGesture(
            minimumDuration: 0.01,
            pressing: { pressing in
                homeViewModel.handleButtonPress(pressing)
            },
            perform: {}
        )
        .accessibilityLabel("Add")
    }
}
