import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/design_system.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const CollegeErpApp());
}

class CollegeErpApp extends StatelessWidget {
  const CollegeErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College ERP',
      debugShowCheckedModeBanner: false,
      theme: erpTheme,
      home: const SplashScreen(),
    );
  }
}
