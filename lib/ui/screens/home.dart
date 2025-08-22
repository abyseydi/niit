import 'package:flutter/material.dart';
import '../../routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        backgroundColor: cs.primaryContainer,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flutter_dash, size: 72, color: cs.primary),
                  const SizedBox(height: 12),
                  // Text(
                  //   'Bienvenue 👋',
                  //   style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  // ),
                  const SizedBox(height: 8),
                  Text(
'POLICE NATIONALE DU SENEGAL, LETS GOOO   ',                 textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.details, arguments: 'Salut depuis Home !');
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Aller aux détails'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                        icon: const Icon(Icons.settings),
                        label: const Text('Paramètres'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
