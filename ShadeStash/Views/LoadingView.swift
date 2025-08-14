//
//  LoadingView.swift
//  ShadeStash
//
//  Created by pranay vohra on 12/08/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        // Your app logo or loading indicator
        VStack {
            // App logo or branding
            ProgressView()
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black) // or your app's theme color
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
