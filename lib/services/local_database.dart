import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class LocalDatabase {
  static const String _notesBoxName = 'notes';
  late Box<Note> _notesBox;

  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());

    try {
      _notesBox = await Hive.openBox<Note>(_notesBoxName);
    } catch (e) {
      // If there's an error opening the box (likely due to schema change),
      // delete the old box and create a new one
      await Hive.deleteBoxFromDisk(_notesBoxName);
      _notesBox = await Hive.openBox<Note>(_notesBoxName);
    }
  }

  // Get all notes for a specific user sorted by newest first
  List<Note> getAllNotes(String userId) {
    try {
      final notes = _notesBox.values
          .where((note) => note.userId == userId)
          .toList();
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    } catch (e) {
      // If there's an error reading notes, return empty list
      return [];
    }
  }

  // Get a single note by ID
  Note? getNoteById(String id) {
    return _notesBox.values.firstWhere(
      (note) => note.id == id,
      orElse: () => Note(
        id: '',
        title: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: '',
      ),
    );
  }

  // Add a new note
  Future<void> addNote(Note note) async {
    await _notesBox.put(note.id, note);
  }

  // Update an existing note
  Future<void> updateNote(Note note) async {
    await _notesBox.put(note.id, note);
  }

  // Delete a note
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  // Get all unsynced notes for a specific user
  List<Note> getUnsyncedNotes(String userId) {
    return _notesBox.values
        .where((note) => note.userId == userId && !note.isSynced)
        .toList();
  }

  // Mark a note as synced
  Future<void> markAsSynced(String id) async {
    final note = getNoteById(id);
    if (note != null && note.id.isNotEmpty) {
      final updatedNote = note.copyWith(isSynced: true);
      await updateNote(updatedNote);
    }
  }

  // Clear all notes (for testing or logout)
  Future<void> clearAll() async {
    await _notesBox.clear();
  }

  // Close the database
  Future<void> close() async {
    await _notesBox.close();
  }
}
