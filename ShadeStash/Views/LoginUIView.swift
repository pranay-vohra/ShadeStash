//
//  LoginUIView.swift
//  ShadeStash
//
//  Created by pranay vohra on 12/08/25.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import AuthenticationServices

struct LoginUIView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Text("Welcome")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    
                    
                    Text("Sign in or create\nan account")
                        .font(.system(size: 40))
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 40)
                    
                    Text("Colors you choose, always with you.")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                .padding(.bottom, 80)
         
                   
                
                Spacer()
              

                VStack(spacing: 24) {
                    // Error Message
                    if !viewModel.errorMessage.isEmpty {
                        VStack {
                            Text(viewModel.errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Dismiss") {
                                viewModel.clearError()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 30)
                    }
                    
                    HStack {
                        SignInWithAppleButton(.signIn) { request in
                    
                            viewModel.startSignInWithAppleFlow()
                        } onCompletion: { result in
                            switch result {
                            case .success:
                                viewModel.authenticationState = .authenticating
                                viewModel.handleSignInWithAppleCompletion(result)
                            case .failure:
                                viewModel.authenticationState = .unauthenticated
                                viewModel.errorMessage = "Sign in was cancelled or failed"
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .padding(.top, 8)
                    .disabled(viewModel.isLoading || viewModel.authenticationState == .authenticating)
                    .padding(.horizontal, 24)
                    // Google Sign In Button
                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack(spacing: 4) {
                            // Google Logo
                            Image("Google")
                                .resizable()
                                .frame(width: 20, height: 20)
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                            } else {
                                Text("Continue with Google")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .padding(.top, 4)
                    }
                    .disabled(viewModel.isLoading || viewModel.authenticationState == .authenticating)
                    .padding(.horizontal, 24)
                    Spacer()
                    Spacer()
                    
                    // Terms and Privacy
                    VStack(spacing: 4) {
                        HStack {
                            Text("By continuing you agree to")
                                .font(.callout)
                                .foregroundColor(.secondary)
                               
                            Button("Terms of Service") {
                                // Handle terms tap
                            }
                            .font(.callout)
                            .foregroundColor(.primary)
                            
                            Text("and")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        Button("Privacy Policy") {
                            // Handle privacy policy tap
                        }
                        .font(.callout)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.clearError()
        }
    }
    
    private func signInWithGoogle() {
        Task {
            let success = await viewModel.signInWithGoogle()
            if success {
                print(" Sign in successful")

            }
        }
    }
}

#Preview {
    LoginUIView()
        .environmentObject(AuthViewModel())
}
