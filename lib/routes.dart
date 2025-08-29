import 'package:flutter/material.dart';
import 'package:niit/ui/screens/details.dart';
import 'package:niit/ui/screens/home.dart';
import 'package:niit/ui/screens/settings.dart';


class AppRoutes {
  static const home = '/';
  static const details = '/details';
  static const settings = '/settings';

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) =>  HomePage());
      case details:
        final String? message = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => DetailsScreen(message: message));
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404 - Page not found')),
          ),
        );
    }
  }
}
