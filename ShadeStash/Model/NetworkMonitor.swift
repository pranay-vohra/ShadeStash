//
//  NetworkMonitor.swift
//  ShadeStash
//

import Foundation
import Network
import SwiftUI

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasConnected = self?.isConnected ?? false
                let isNowConnected = path.status == .satisfied
                
                self?.isConnected = isNowConnected
                self?.connectionType = path.availableInterfaces.first?.type
                
                // Log network changes for debugging
                if wasConnected != isNowConnected {
                    print("🔄 Network status changed: \(isNowConnected ? "Connected" : "Disconnected")")
                    if isNowConnected {
                        print("📡 Connection type: \(self?.connectionType?.debugDescription ?? "Unknown")")
                    }
                }
            }
        }
        
        networkMonitor.start(queue: workerQueue)
        print("🔍 Network monitoring started")
    }
    
    func stopMonitoring() {
        networkMonitor.cancel()
        print("🛑 Network monitoring stopped")
    }
    
    deinit {
        Task { @MainActor in
            stopMonitoring()
        }
    }
}

extension NWInterface.InterfaceType {
    var debugDescription: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}
