import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Needed for the Cart Logic
import 'firebase_options.dart';

// Imports for your specific app files
import 'src/constants/theme.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/client_home/cart_provider.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready before Firebase starts
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase connection
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Run the App wrapped in the Provider
  runApp(
    MultiProvider(
      providers: [
        // This makes the Cart available to every screen in the app
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const KedaiKitaApp(),
    ),
  );
}

class KedaiKitaApp extends StatelessWidget {
  const KedaiKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kedai Kita',
      
      // Use the theme we defined in src/constants/theme.dart
      theme: appTheme,
      
      // Remove the "Debug" banner from the top right
      debugShowCheckedModeBanner: false,
      
      // Start the app at the Login Screen
      home: const LoginScreen(),
    );
  }
}