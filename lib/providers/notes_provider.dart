import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/local_database.dart';
import '../services/sync_manager.dart';
import '../services/auth_service.dart';

class NotesProvider extends ChangeNotifier {
  final LocalDatabase _localDb;
  final SyncManager _syncManager;
  final AuthService _authService;

  List<Note> _notes = [];
  bool _isLoading = false;

  NotesProvider({
    required LocalDatabase localDatabase,
    required SyncManager syncManager,
    required AuthService authService,
  }) : _localDb = localDatabase,
       _syncManager = syncManager,
       _authService = authService {
    loadNotes();
  }

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  String? get _currentUserId => _authService.currentUser?.uid;

  // Load all notes from local database
  Future<void> loadNotes() async {
    if (_currentUserId == null) {
      _notes = [];
      return;
    }

    _isLoading = true;
    notifyListeners();

    _notes = _localDb.getAllNotes(_currentUserId!);

    _isLoading = false;
    notifyListeners();
  }

  // Add a new note
  Future<void> addNote(Note note) async {
    if (_currentUserId == null) return;

    await _localDb.addNote(note);
    await _syncManager.syncNote(note);
    await loadNotes();
  }

  // Update an existing note
  Future<void> updateNote(Note note) async {
    if (_currentUserId == null) return;

    final updatedNote = note.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await _localDb.updateNote(updatedNote);
    await _syncManager.syncNote(updatedNote);
    await loadNotes();
  }

  // Delete a note
  Future<void> deleteNote(String id) async {
    if (_currentUserId == null) return;

    await _syncManager.deleteNote(id);
    await loadNotes();
  }

  // Get a single note by ID
  Note? getNoteById(String id) {
    return _localDb.getNoteById(id);
  }

  // Refresh notes (manual sync)
  Future<void> refresh() async {
    if (_currentUserId == null) return;

    await _syncManager.syncNotes();
    await loadNotes();
  }
}
