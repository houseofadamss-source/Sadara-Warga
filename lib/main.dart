import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'widgets/offline_wrapper.dart';
import 'injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Muat file .env rahasia
    await dotenv.load(fileName: ".env");
    
    // 2. Inisialisasi Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    // 3. Inisialisasi Dependency Injection (Clean Architecture)
    await di.init();
    
  } catch (e) {
    debugPrint('Initialization Error: $e');
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
        child: isLoggedIn ? const HomePage() : const WelcomePage(),
      ),
    );
  }
}
