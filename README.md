# Whispr: Secure Identity & Access Management

![Whispr Logo](assets/app_icon.png)

**Whispr** is a modern, privacy-first security suite designed to protect your digital life with elegance and ease. Built with a premium glassmorphic interface, Whispr combines a robust Password Manager, a secure TOTP Authenticator, and AI-powered Security Coaching to ensure you're always one step ahead of threats.

---

## 📸 Screenshots Showcase

| Home Dashboard | Password Vault | AI Security Coach |
| :---: | :---: | :---: |
| ![Home](screenshots/home.png) | ![Vault](screenshots/vault.png) | ![Coach](screenshots/ai_coach.png) |
| *The heart of your digital security.* | *Elegant, end-to-end encrypted storage.* | *Proactive insights from Gemini AI.* |

---

## ✨ Key Features

### 🛡️ Secure Password Manager
- **Zero-Knowledge Architecture**: Your data is encrypted locally before ever reaching the cloud.
- **AES-256 Encryption**: Industry-standard encryption for maximum security.
- **Biometric Unlock**: Access your vault instantly with fingerprint or facial recognition.
- **Credential Analysis**: Automatic detection of weak, old, or reused passwords.

### 🔑 TOTP Authenticator
- **2FA Support**: Compatible with all services offering Time-based One-Time Passwords.
- **Real-time Sync**: Keep your authentication codes synced securely across your devices.
- **Scan & Go**: Effortlessly add accounts using the built-in QR code scanner.

### 🤖 AI Security Coaching (Powered by Gemini)
- **Privacy-Preserving Audit**: We only send metadata to the AI; your actual passwords never leave your device.
- **Actionable Insights**: Get human-readable interpretations of your security posture.
- **Risk Mitigation**: Prioritized suggestions on what to fix first based on industry best practices.

### 🎨 Premium Design
- **Glassmorphism UI**: A stunning, modern interface that feels light and premium.
- **Native Experience**: Smooth 60fps animations and transitions.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (Cross-platform excellence)
- **Backend/Auth**: [Supabase](https://supabase.com) (Secure database & identity)
- **Artificial Intelligence**: [Google Gemini 2.5 Flash](https://deepmind.google/technologies/gemini/) (Security coaching)
- **Local Security**: `flutter_secure_storage` & `local_auth`

---

## 🔒 Security & Privacy

Privacy is not a feature; it's our foundation. 
- All encryption keys are stored in the device's secure hardware (Keystore/Keychain).
- We use a custom "Whispr-Salt" for vault derivation to prevent rainbow table attacks.
- Open-source spirit with closed-vault security.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.10.7)
- Supabase account & credentials
- Gemini API Key

### Setup
1. Clone the repository.
2. Create a `.env` file in the root directory.
3. Add your credentials:
   ```env
   SUPABASE_URL=your_url
   SUPABASE_ANON_KEY=your_key
   GEMINI_API_KEY=your_gemini_key
   ```
4. Run `flutter pub get`.
5. Run the app: `flutter run`.

---

## 📝 Suggested Screenshots for Play Store
1. **The Hero Shot**: The Home Dashboard showing the Glassmorphic TOTP codes.
2. **The Vault**: The Password Manager list with account icons.
3. **The Brain**: The AI Security Audit results screen with the interpretation text.
4. **The Lock**: The Biometric Authentication prompt.
5. **The Add Flow**: Adding a new password with the specialized input fields.

---

© 2026 Whispr Project. All Rights Reserved.
