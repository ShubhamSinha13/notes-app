import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's notes collection
  CollectionReference _getUserNotesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  // Upload a note to Firestore
  Future<void> uploadNote(String userId, Note note) async {
    try {
      await _getUserNotesCollection(userId).doc(note.id).set(note.toMap());
    } catch (e) {
      throw 'Failed to upload note: $e';
    }
  }

  // Download all notes from Firestore
  Future<List<Note>> downloadNotes(String userId) async {
    try {
      final snapshot = await _getUserNotesCollection(userId).get();
      return snapshot.docs.map((doc) {
        return Note.fromMap(doc.data() as Map<String, dynamic>, userId);
      }).toList();
    } catch (e) {
      throw 'Failed to download notes: $e';
    }
  }

  // Delete a note from Firestore
  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _getUserNotesCollection(userId).doc(noteId).delete();
    } catch (e) {
      throw 'Failed to delete note: $e';
    }
  }

  // Update a note in Firestore
  Future<void> updateNote(String userId, Note note) async {
    try {
      await _getUserNotesCollection(userId).doc(note.id).update(note.toMap());
    } catch (e) {
      throw 'Failed to update note: $e';
    }
  }

  // Listen to notes changes (real-time)
  Stream<List<Note>> notesStream(String userId) {
    return _getUserNotesCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Note.fromMap(doc.data() as Map<String, dynamic>, userId);
      }).toList();
    });
  }
}
