import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/local_database.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/sync_manager.dart';
import 'providers/notes_provider.dart';
import 'screens/login_screen.dart';
import 'screens/notes_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize local database
  final localDb = LocalDatabase();
  await localDb.init();

  runApp(MyApp(localDatabase: localDb));
}

class MyApp extends StatelessWidget {
  final LocalDatabase localDatabase;

  const MyApp({super.key, required this.localDatabase});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final syncManager = SyncManager(
      localDatabase: localDatabase,
      firestoreService: firestoreService,
    );

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Initialize sync manager when user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          syncManager.init(snapshot.data!.uid);
        }

        // Use userId as key to recreate provider when user changes
        final userId = snapshot.data?.uid ?? 'no-user';

        return MultiProvider(
          key: ValueKey(userId),
          providers: [
            ChangeNotifierProvider(
              create: (_) => NotesProvider(
                localDatabase: localDatabase,
                syncManager: syncManager,
                authService: authService,
              ),
            ),
          ],
          child: MaterialApp(
            title: 'Offline Notes',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF1a1a1a),
              primaryColor: const Color(0xFF2c2c2c),
              cardColor: const Color(0xFF2c2c2c),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF0d0d0d),
                elevation: 0,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFF404040),
              ),
              useMaterial3: true,
            ),
            home: snapshot.connectionState == ConnectionState.waiting
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : snapshot.hasData
                ? const NotesListScreen()
                : const LoginScreen(),
          ),
        );
      },
    );
  }
}
