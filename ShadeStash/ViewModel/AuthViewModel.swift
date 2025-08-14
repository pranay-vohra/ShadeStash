//
//  AuthViewModel.swift
//  ShadeStash
//
//  Created by pranay vohra on 12/08/25.
//

import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum AuthenticationError: Error, LocalizedError {
    case tokenError(message: String)
    case configurationError(message: String)
    case networkError(message: String)
    case userCancelled
    case unknownError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .tokenError(let message):
            return "Token Error: \(message)"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .userCancelled:
            return "Sign in was cancelled"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
}


@MainActor
class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var isValid: Bool  = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var errorMessage: String = ""
    @Published var user: User?
    @Published var displayName: String = ""
    @Published var isLoading: Bool = false
    @Published  var currentNonce:String?
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        registerAuthStateHandler()
        configureGoogleSignIn()
    }
    
    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func configureGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ No client ID found in Firebase configuration")
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        print("✅ Google Sign-In configured successfully")
    }
    
    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.user = user
                    self.authenticationState = user == nil ? .unauthenticated : .authenticated
                    self.displayName = user?.displayName ?? user?.email ?? ""
                    self.email = user?.email ?? ""
                    
                    if user != nil {
                        print("✅ User authenticated: \(user?.email ?? "unknown")")
                    } else {
                        print("🔐 User signed out")
                    }
                }
            }
        }
    }

    func clearError() {
           errorMessage = ""
       }
    
    private func wait() async {
        do {
            print("Wait")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            print("Done")
        }
        catch { }
    }
    
}

extension AuthViewModel {
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            displayName = ""
            email = ""
            authenticationState = .unauthenticated
            print("✅ User signed out successfully")
        }catch {
            print("❌ Sign out error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    
    func deleteAccount() async -> Bool {
        guard let user = user else {
            errorMessage = "No user to delete"
            return false
        }
        
        do {
            try await user.delete()
            print("✅ User account deleted successfully")
            return true
        } catch {
            print("❌ Delete account error: \(error)")
            errorMessage = error.localizedDescription
            return false
        }
    }
}

//sign in with google

extension AuthViewModel {
    func signInWithGoogle() async -> Bool {
        errorMessage = ""
        authenticationState = .authenticating
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        do {
            // Verify configuration
            guard GIDSignIn.sharedInstance.configuration != nil else {
                throw AuthenticationError.configurationError(message: "Google Sign-In not configured")
            }
            
            // Get root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                throw AuthenticationError.configurationError(message: "No root view controller found")
            }
            
            print("🔐 Starting Google Sign-In...")
            
            // Perform Google Sign In
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            let user = userAuthentication.user
            guard let idToken = user.idToken?.tokenString else {
                throw AuthenticationError.tokenError(message: "ID token missing")
            }
            
            let accessToken = user.accessToken.tokenString
            
            print("🔑 Tokens obtained, signing in with Firebase...")
            
            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
            
            // Sign in with Firebase
            let result = try await Auth.auth().signIn(with: credential)
            let firebaseUser = result.user
            
            print("✅ User \(firebaseUser.uid) signed in with email \(firebaseUser.email ?? "unknown")")
            
            authenticationState = .authenticated
            return true
            
        } catch let error as NSError {
            print("❌ Google Sign-In error: \(error)")
            
            authenticationState = .unauthenticated
            
            // Handle specific error cases
            if error.domain == "com.google.GIDSignIn" && error.code == -5 {
                // User cancelled
                print("🚫 User cancelled sign in")
                return false // Don't show error message for cancellation
            } else if error.localizedDescription.contains("network") {
                errorMessage = AuthenticationError.networkError(message: "Please check your internet connection").localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            
            return false
        }
    }
}


//sign in with apple
extension AuthViewModel{
    func startSignInWithAppleFlow() {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
      request.nonce = sha256(nonce)
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential else {
                print("Unexpected credential type")
                return
            }

            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }

            guard let appleIDToken = appleIDCredential.identityToken else {
                fatalError("Unable to fetch identity token")
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error {
                    print("Firebase sign-in error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }

                guard let user = authResult?.user else {
                    self?.errorMessage = "No user returned"
                    return
                }

                // Set displayName if available from Apple (only on first sign-in)
                if let fullName = appleIDCredential.fullName {
                    let formatter = PersonNameComponentsFormatter()
                    let name = formatter.string(from: fullName)
                    
                    if !name.isEmpty {
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = name
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("Failed to set display name: \(error.localizedDescription)")
                            } else {
                                print(" Display name updated to: \(name)")
                            }
                        }
                    }
                }

                DispatchQueue.main.async {
                    self?.authenticationState = .authenticated
                }
            }

        case .failure(let error):
            print("❌ Apple Sign In failed: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }

        
}
