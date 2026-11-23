import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Core/auth_provider.dart';
import 'Core/theme_provider.dart';
import 'Core/font_provider.dart';
import 'Screens/Auth/login_screen.dart';
import 'Screens/Home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final fontProvider = context.watch<FontProvider>();
    final authProvider = context.watch<AuthProvider>();

    // بناء الثيم بشكل ديناميكي من ThemeProvider
    Widget home;
    switch (authProvider.status) {
      case AuthStatus.checking:
        home = const _SplashScreen();
        break;
      case AuthStatus.authenticated:
        home = const HomeScreen();
        break;
      case AuthStatus.unauthenticated:
        home = const LoginScreen();
        break;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Note App',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // تطبيق مقياس الخط عبر كامل التطبيق
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontProvider.textScaleFactor),
          ),
          child: child!,
        );
      },
      home: home,
    );
  }
}

/// شاشة انتظار بينما يتحقق AuthProvider من الجلسة المحفوظة
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 44,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: cs.primary),
          ],
        ),
      ),
    );
  }
}
