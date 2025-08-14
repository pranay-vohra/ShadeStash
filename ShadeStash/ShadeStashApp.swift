//
//  ShadeStashApp.swift
//  ShadeStash
//
//  Created by pranay vohra on 12/08/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}


@main
struct ShadeStashApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkMonitor)
                .environmentObject(authViewModel)
                .modelContainer(for: [Card.self])
                .onAppear {
                    print("🚀 App launched - Network: \(networkMonitor.isConnected ? "Connected" : "Disconnected")")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    print("📱 App will resign active")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    print("📱 App did become active - Network: \(networkMonitor.isConnected ? "Connected" : "Disconnected")")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    print("📱 App will terminate")
                    networkMonitor.stopMonitoring()
                }
        }
        .modelContainer(for: [Card.self])
    }
}
