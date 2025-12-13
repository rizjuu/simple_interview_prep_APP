import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:interview_prep/screens/home_page.dart';
import 'package:interview_prep/services/cart_service.dart';
import 'package:interview_prep/screens/checkout_page.dart';
import 'package:interview_prep/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartService()),
        ChangeNotifierProvider(create: (context) => ThemeService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Neon color palette
    const Color neonViolet = Color(0xFF6C63FF);
    const Color deepSpaceBlack = Color(0xFF0F0F1A);
    const Color mintNeon = Color(0xFF00F5D4);
    const Color background = Color(0xFF1A1A2E);
    const Color textColor = Color(0xFFE2E2E2);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E Commerce Shopping yeah',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: neonViolet,
          secondary: mintNeon,
          surface: background,
          onPrimary: Colors.white,
          onSecondary: deepSpaceBlack,
          onSurface: textColor,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: deepSpaceBlack,
          foregroundColor: textColor,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2A2A3E),
          elevation: 8,
          shadowColor: neonViolet.withOpacity(0.3),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonViolet,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: neonViolet.withOpacity(0.5),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: mintNeon),
        ),
        iconTheme: const IconThemeData(color: mintNeon),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: deepSpaceBlack,
          selectedItemColor: mintNeon,
          unselectedItemColor: Color(0xFF666E8F),
          elevation: 8,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: neonViolet,
          secondary: mintNeon,
          surface: background,
          onPrimary: Colors.white,
          onSecondary: deepSpaceBlack,
          onSurface: textColor,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: deepSpaceBlack,
          foregroundColor: textColor,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2A2A3E),
          elevation: 8,
          shadowColor: neonViolet.withOpacity(0.3),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonViolet,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: neonViolet.withOpacity(0.5),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: mintNeon),
        ),
        iconTheme: const IconThemeData(color: mintNeon),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: deepSpaceBlack,
          selectedItemColor: mintNeon,
          unselectedItemColor: Color(0xFF666E8F),
          elevation: 8,
        ),
      ),
      home: const HomePage(),
      routes: {'/checkout': (context) => CheckoutPage(items: [])},
    );
  }
}
