import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_database.dart';
import 'firestore_service.dart';
import '../models/note.dart';

class SyncManager {
  final LocalDatabase _localDb;
  final FirestoreService _firestoreService;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  String? _currentUserId;

  SyncManager({
    required LocalDatabase localDatabase,
    required FirestoreService firestoreService,
  }) : _localDb = localDatabase,
       _firestoreService = firestoreService;

  // Initialize sync manager and listen to connectivity changes
  void init(String userId) {
    _currentUserId = userId;
    _listenToConnectivity();
    // Perform initial sync
    syncNotes();
  }

  // Listen to connectivity changes
  void _listenToConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Check if we have any connection
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (hasConnection && !_isSyncing) {
        syncNotes();
      }
    });
  }

  // Check if device is online
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  // Sync local notes to Firestore
  Future<void> syncNotes() async {
    if (_currentUserId == null || _isSyncing) return;

    final online = await isOnline();
    if (!online) return;

    _isSyncing = true;

    try {
      // Get unsynced notes from local database
      final unsyncedNotes = _localDb.getUnsyncedNotes(_currentUserId!);

      // Upload each unsynced note
      for (final note in unsyncedNotes) {
        try {
          await _firestoreService.uploadNote(_currentUserId!, note);
          await _localDb.markAsSynced(note.id);
        } catch (e) {
          // Continue with other notes if one fails
          continue;
        }
      }

      // Download notes from Firestore and merge with local
      await _downloadAndMergeNotes();
    } catch (e) {
      // Sync failed silently
    } finally {
      _isSyncing = false;
    }
  }

  // Download notes from Firestore and merge with local database
  Future<void> _downloadAndMergeNotes() async {
    if (_currentUserId == null) return;

    try {
      final remoteNotes = await _firestoreService.downloadNotes(
        _currentUserId!,
      );
      final localNotes = _localDb.getAllNotes(_currentUserId!);

      // Create a map of local notes for quick lookup
      final localNotesMap = {for (var note in localNotes) note.id: note};

      for (final remoteNote in remoteNotes) {
        final localNote = localNotesMap[remoteNote.id];

        if (localNote == null) {
          // Note doesn't exist locally, add it
          await _localDb.addNote(remoteNote);
        } else {
          // Note exists, use last-write-wins based on updatedAt
          if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
            await _localDb.updateNote(remoteNote);
          }
        }
      }
    } catch (e) {
      // Download failed silently
    }
  }

  // Sync a single note immediately
  Future<void> syncNote(Note note) async {
    if (_currentUserId == null) return;

    final online = await isOnline();
    if (!online) return;

    try {
      await _firestoreService.uploadNote(_currentUserId!, note);
      await _localDb.markAsSynced(note.id);
    } catch (e) {
      // Sync failed silently
    }
  }

  // Delete note from both local and remote
  Future<void> deleteNote(String noteId) async {
    // Delete locally first
    await _localDb.deleteNote(noteId);

    // Try to delete from Firestore if online
    if (_currentUserId != null) {
      final online = await isOnline();
      if (online) {
        try {
          await _firestoreService.deleteNote(_currentUserId!, noteId);
        } catch (e) {
          // Deletion from Firestore failed silently
        }
      }
    }
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
