import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/sensor_dashboard_screen.dart';
import 'screens/rower_control_screen.dart';
import 'services/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize translation service
  await TranslationService().init();

  // Set status bar globally
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const FarmerIoTApp());
}

class FarmerIoTApp extends StatelessWidget {
  const FarmerIoTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService().currentLanguage,
      builder: (context, langCode, child) {
        return MaterialApp(
          title: TranslationService().translate('app_title'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B5E20),
              brightness: Brightness.light,
              primary: const Color(0xFF1B5E20),
              secondary: const Color(0xFF558B2F),
              surface: const Color(0xFFF5F5DC),
              background: const Color(0xFFFAF9F6),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5DC),
            fontFamily: 'Roboto',
          ),
          // Splash is the entry point
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/sensors': (context) => const SensorDashboardScreen(),
            '/rower': (context) => const RowerControlScreen(),
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const SensorDashboardScreen(),
            );
          },
        );
      },
    );
  }
}
