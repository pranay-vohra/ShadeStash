# ShadeStash

ShadeStash is an iOS app that allows users to generate and store color cards locally and in the cloud, with full offline support and real-time sync.  
It uses **Swift**, **SwiftUI**, and **SwiftData** for local storage, and **Firebase Firestore** for cloud storage.  
The app also integrates **Apple Intelligence** (iOS 26+) for color insights, authentication via **Apple** and **Google**, and real-time network status monitoring.
![SignIn View](https://drive.google.com/file/d/1htxZav1grxjbW_ztZRlnf2g0g_fIGtsr/view?usp=sharing)
---

## ✨ Features

- **Apple Intelligence Foundation Model (iOS 26+ only)**
  - Works even **offline**.
  - Gives fun facts about the selected color.
  - Suggests complementary colors for better color pairing.
  - Makes the app more interactive and engaging.
  - Requires iOS 26 beta, Xcode 26 beta, and macOS 26 beta.

- **Color Card Management**
  - Generate random hex color codes.
  - View and manage cards with color name and hex code.

- **Offline-first Support**
  - Save data locally using **SwiftData**.
  - Auto-sync with **Firebase Firestore** when network is available.

- **User Authentication**
  - Sign in with **Apple** or **Google** accounts.
  - Secure authentication using Firebase Auth.

- **Connectivity Awareness**
  - Built-in **Network Monitor** to observe and display network status in the header and profile view.
  - Auto-sync when coming online.

- **Robust Error Handling**
  - Graceful error messages for authentication, network, and data sync issues.
  - Retry logic for failed sync operations.

- **Clean Architecture**
  - Built with **MVVM** for scalability and maintainability.
  - Well-structured code with clear separation of concerns.

---

## 🛠 Requirements

- **iOS**:  
  - iOS 16.0+ for core app functionality.  
  - iOS 26.0+ for Apple Intelligence features.
- **macOS**: macOS 26 beta  
  Download: [macOS 26 Beta](https://developer.apple.com/download/#ios-restore-images-ipad-new)
- **Xcode**: Xcode 26 beta  
  Download: [Xcode 26 Beta](https://developer.apple.com/download/applications/)
- **Firebase Project**:
  - Firestore enabled
  - Google Sign-In configured
  - Apple Sign-In configured

---

## 🚀 Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/shadestash.git
   cd shadestash
   ```

2. **Install dependencies**:
   - Open the project in **Xcode 26 beta**.
   - Ensure your Firebase GoogleService-Info.plist file is added to the project.

3. **Run the app**:
   - Select a device or simulator running **iOS 26 beta** (for Apple Intelligence) or iOS 16+ (core features).
   - Press Cmd + R.

---
📜 License

This project is licensed under the MIT License — see the LICENSE file for details.
---
