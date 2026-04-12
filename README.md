# Mafia Game Monorepo

This repository contains the full-stack implementation of a multiplayer Mafia party game with a Flutter frontend and a Firebase backend.

## Project Structure

- `/app` - The Flutter application (Android & iOS).
- `/functions` - Firebase Cloud Functions (TypeScript) containing secure game logic.
- `/firebase` - Firebase configuration and Realtime Database rules.

## Setup Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/en/) (v18+)
- [Firebase CLI](https://firebase.google.com/docs/cli)

### Backend Setup (Firebase)
1. Initialize your Firebase project:
   ```bash
   firebase login
   firebase init
   ```
   *Select Realtime Database and Functions. Choose TypeScript for Functions.*
2. Deploy Realtime Database rules:
   ```bash
   firebase deploy --only database
   ```
3. Deploy Cloud Functions:
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions
   ```

### Frontend Setup (Flutter)
1. Configure Firebase for the Flutter app:
   ```bash
   cd app
   flutterfire configure
   ```
2. Run the app:
   ```bash
   flutter run
   ```

## Development (Local Emulator)
To test locally without modifying your production database:
1. Start Firebase Emulators:
   ```bash
   firebase emulators:start
   ```
2. Run the Flutter app with local connections (ensure your app config points to local).
