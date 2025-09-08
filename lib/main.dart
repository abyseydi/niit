import 'package:flutter/material.dart';
import 'package:niit/ui/screens/homescreen.dart';
import 'app_theme.dart';
import 'routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accel Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light, // Thème centralisé
      onGenerateRoute: AppRoutes.generate, // Gestionnaire de routes
      home: HomeScreen(), // Écran d’accueil
    );
  }
}
