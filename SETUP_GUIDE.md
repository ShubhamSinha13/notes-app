# Offline-First Notes App

A simple Flutter notes application that works offline-first, with Firebase authentication and automatic cloud sync when online.

## Features

- ✅ Email/Password authentication with Firebase
- ✅ Create, edit, and delete notes
- ✅ Offline-first architecture using Hive local database
- ✅ Automatic silent sync to Firestore when online
- ✅ Notes sorted by newest first
- ✅ Online/offline status indicator
- ✅ Sync status indicator for each note
- ✅ Last-write-wins conflict resolution

## Tech Stack

- **Flutter/Dart** - UI framework
- **Firebase Auth** - User authentication
- **Cloud Firestore** - Remote database
- **Hive** - Local database
- **Provider** - State management
- **Connectivity Plus** - Network detection

## Setup Instructions

### 1. Firebase Configuration

**IMPORTANT:** You must set up Firebase before running the app.

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard

#### Step 2: Enable Authentication
1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Click on **Email/Password**
3. Toggle **Enable** and click **Save**

#### Step 3: Enable Firestore
1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Start in **Test mode** (for development)
4. Choose a location and click **Enable**

#### Step 4: Add Android App
1. In Firebase Console, click the Android icon to add Android app
2. Enter package name: `com.example.flutter_application_1`
3. Download `google-services.json`
4. **Replace** the placeholder file at `android/app/google-services.json` with your downloaded file

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

#### On Android Emulator:
1. Open Android Studio
2. Start an Android Virtual Device (AVD)
3. Run the app:
```bash
flutter run
```

#### On Physical Device:
```bash
flutter run
```

## How to Use

### First Time Setup
1. Launch the app
2. Click "Don't have an account? Sign up"
3. Enter email and password (minimum 6 characters)
4. Click "Sign Up"

### Creating Notes
1. Tap the **+** button at the bottom right
2. Enter a title and content
3. Tap the **Save** icon in the app bar
4. Note is saved locally immediately

### Editing Notes
1. Tap any note from the list
2. Edit the title or content
3. Tap the **Save** icon
4. Changes are saved locally and queued for sync

### Deleting Notes
1. Tap the **Delete** icon on any note
2. Confirm deletion in the dialog
3. Note is deleted locally and from cloud (when online)

### Sync Indicators
- **Cloud icon** in app bar: Green = Online, Gray = Offline
- **Check/Sync icon** on notes: Green check = Synced, Orange sync = Pending sync

### Testing Offline Mode
1. Create some notes while online
2. Enable **Airplane mode** on the device
3. Create/edit more notes - they work offline!
4. Disable Airplane mode
5. Notes automatically sync in the background

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── note.dart               # Note model
│   └── note.g.dart             # Generated Hive adapter
├── services/
│   ├── auth_service.dart       # Firebase authentication
│   ├── firestore_service.dart  # Firestore operations
│   ├── local_database.dart     # Hive local storage
│   └── sync_manager.dart       # Sync coordination
├── providers/
│   └── notes_provider.dart     # State management
└── screens/
    ├── login_screen.dart       # Login UI
    ├── signup_screen.dart      # Signup UI
    ├── notes_list_screen.dart  # Notes list UI
    └── note_editor_screen.dart # Note editor UI
```

## Architecture

### Offline-First Flow
1. **Write Operations**: All create/update/delete operations save to local Hive database first
2. **Instant Response**: UI updates immediately from local data
3. **Background Sync**: When online, changes automatically sync to Firestore
4. **Conflict Resolution**: Last-write-wins based on `updatedAt` timestamp

### Data Flow
```
User Action
    ↓
Local Database (Hive) - Immediate save
    ↓
UI Update (Provider) - Instant feedback
    ↓
Sync Manager - Background sync
    ↓
Firestore (when online) - Cloud persistence
```

## Troubleshooting

### App won't build
- Ensure `google-services.json` is properly configured
- Run `flutter clean` then `flutter pub get`
- Check that minSdk is 21 or higher in `android/app/build.gradle.kts`

### Sync not working
- Check internet connection
- Verify Firestore is enabled in Firebase Console
- Check Firestore security rules (should allow authenticated users)

### Login/Signup fails
- Verify Email/Password authentication is enabled in Firebase
- Check for valid email format
- Ensure password is at least 6 characters

## Firestore Security Rules

For production, update Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/notes/{noteId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Future Enhancements

Potential features to add:
- Search functionality
- Tags/categories
- Rich text formatting
- Note sharing
- Biometric authentication
- Export/import notes
- Dark mode

## License

This project is for educational purposes.
