import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/offline_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://bexwegvrpigxpfpwfjih.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJleHdlZ3ZycGlneHBmcHdmamloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2MDgzNjksImV4cCI6MjA5NjE4NDM2OX0.goGAk1hBVEqQ23szxqmFYYG-BQFHsXYL9T4OzO_zevc',
    );
  } catch (e) {
    debugPrint('Supabase Init Error: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(SadaraApp(isLoggedIn: isLoggedIn));
}

class SadaraApp extends StatelessWidget {
  final bool isLoggedIn;
  const SadaraApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sadara Warga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
      ),
      home: OfflineWrapper(
        child: isLoggedIn ? const HomeScreen() : const WelcomeScreen(),
      ),
    );
  }
}
