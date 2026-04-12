# Mafia Go (Serverless Architecture)

This repository contains the completely serverless implementation of a multiplayer Mafia party game built with a Flutter frontend and Firebase Realtime Database. The game relies entirely on client-side state management, allowing the backend to remain 100% on the Firebase free tier.

## Project Structure

- `/app` - The Flutter application (Android & iOS).
- `/firebase` - Firebase configuration and Realtime Database rules.
- `/scripts` - Node.js cleanup scripts for keeping the database tidy over time.
- `/.github` - GitHub Actions for automating backend sweeps.

## Setup Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Firebase CLI](https://firebase.google.com/docs/cli)

### Backend Setup (Firebase)
Because all logic runs locally on the devices, your database essentially acts as a simple, free-tier state synchronizer.
1. Initialize your Firebase project:
   ```bash
   firebase login
   firebase init
   ```
   *Select ONLY Realtime Database.*
2. Deploy Realtime Database rules:
   ```bash
   firebase deploy --only database
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

### Scheduled Cleanups
To prevent reaching resource caps on Firebase's free Spark plan, an automatic GitHub action (`cleanup.yml`) runs every midnight UTC to prune completed or old games from the database. 
- You MUST upload your `FIREBASE_SERVICE_ACCOUNT` json key as a repository secret inside GitHub for this worker process to successfully authenticate!

## Development (Local Emulator)
To test locally without modifying your production database:
1. Start Firebase Emulators:
   ```bash
   firebase emulators:start
   ```
2. Run the Flutter app with local connections (ensure your app config points to local emulator host).
