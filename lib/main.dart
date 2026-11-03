import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'services/recipe_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
    if (useEmulator) {
      const host = String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
        defaultValue: '10.0.2.2',
      );
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(
        host,
        const int.fromEnvironment(
          'FIRESTORE_EMULATOR_PORT',
          defaultValue: 8081,
        ),
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
    runApp(const RecipeBoxApp());
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Could not initialize Firebase. Please check the client configuration and restart.\n\n$error',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RecipeBoxApp extends StatefulWidget {
  const RecipeBoxApp({super.key});
  @override
  State<RecipeBoxApp> createState() => _RecipeBoxAppState();
}

class _RecipeBoxAppState extends State<RecipeBoxApp> {
  late final Stream<User?> _auth = FirebaseAuth.instance.authStateChanges();
  late final RecipeRepository _repository = RecipeRepository(
    FirebaseFirestore.instance,
  );
  String? _registrationMessage;
  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xffb44d32),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'RecipeBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors.copyWith(
          primary: const Color(0xffb44d32),
          surface: const Color(0xfffffdf8),
        ),
        scaffoldBackgroundColor: const Color(0xfff5f2eb),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff5f2eb),
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        textTheme: const TextTheme(
          displayMedium: TextStyle(
            fontSize: 43,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            color: Color(0xff352923),
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
          ),
          headlineSmall: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xff545a52),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xfffffdf8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xffe4dfd3)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xfffcfbf7),
          errorMaxLines: 3,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffd9d6cc)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffd9d6cc)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: _auth,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Authentication error: ${snapshot.error}'),
              ),
            );
          }
          final user = snapshot.data;
          if (user != null) {
            return ListScreen(
              key: ValueKey(user.uid),
              user: user,
              repository: _repository,
              registrationMessage: _registrationMessage,
            );
          }
          _registrationMessage = null;
          return HomeScreen(
            onLogin: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AuthScreen(register: false, onRegistered: () {}),
              ),
            ),
            onRegister: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AuthScreen(
                  register: true,
                  onRegistered: () {
                    setState(
                      () => _registrationMessage = 'Registration successful',
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
