//
//  ContentView.swift
//  ShadeStash
//
//  Created by pranay vohra on 12/08/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        switch authViewModel.authenticationState{
        case .unauthenticated:
            LoginUIView()
        case .authenticating:
            LoadingView()
        case .authenticated:
            if #available(iOS 26.0, *) {
                HomeUIView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
