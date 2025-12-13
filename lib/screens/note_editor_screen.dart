import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/auth_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isNewNote = true;
  Note? _currentNote;

  @override
  void initState() {
    super.initState();
    _isNewNote = widget.noteId == null;

    if (!_isNewNote) {
      // Load existing note
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notesProvider = Provider.of<NotesProvider>(
          context,
          listen: false,
        );
        _currentNote = notesProvider.getNoteById(widget.noteId!);

        if (_currentNote != null) {
          _titleController.text = _currentNote!.title;
          _contentController.text = _currentNote!.content;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final authService = AuthService();
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note is empty')));
      return;
    }

    if (_isNewNote) {
      // Create new note
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
        userId: currentUserId,
      );

      await notesProvider.addNote(newNote);
    } else {
      // Update existing note
      if (_currentNote != null) {
        final updatedNote = _currentNote!.copyWith(
          title: title,
          content: content,
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        await notesProvider.updateNote(updatedNote);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewNote ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Start typing...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
