// import 'package:flutter/material.dart';
// import '../../routes.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Accueil'),
//         backgroundColor: cs.primaryContainer,
//       ),
//       body: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 520),
//           child: Card(
//             elevation: 0,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Icon(Icons.flutter_dash, size: 72, color: cs.primary),
//                  Image.asset(
//             'assets/img/police_logo.png'),
//                   const SizedBox(height: 12),
//                   // Text(
//                   //   'Bienvenue 👋',
//                   //   style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
//                   // ),
//                   const SizedBox(height: 8),
//                   Text(
// 'POLICE NATIONALE DU SENEGAL, LETS GOOO   ',                 textAlign: TextAlign.center,
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   const SizedBox(height: 24),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       FilledButton.icon(
//                         onPressed: () {
//                           Navigator.pushNamed(context, AppRoutes.details, arguments: 'Salut depuis Home !');
//                         },
//                         icon: const Icon(Icons.open_in_new),
//                         label: const Text('Aller aux détails'),
//                       ),
//                       const SizedBox(width: 12),
//                       OutlinedButton.icon(
//                         onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
//                         icon: const Icon(Icons.settings),
//                         label: const Text('Paramètres'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

void main() {
  runApp(MyPoliceApp());
}

class MyPoliceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Police Nationale - Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('POLICE NATIONALE'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(context, Icons.map, 'Géolocalisation', () {
              // Action à définir
            }),
            _buildCard(context, Icons.report, 'Signalements', () {
              // Action à définir
            }),
            _buildCard(context, Icons.notification_important, 'Alertes', () {
              // Action à définir
            }),
            _buildCard(context, Icons.assignment, 'Interventions', () {
              // Action à définir
            }),
            // _buildCard(context, Icons.report_g https://cdn.iconscout.com/icon/free/png-256/report-1709794-1453547.png,
            //  'Rapports', () {
            //   // Action à définir
            // }),
            _buildCard(context, Icons.settings, 'Paramètres', () {
              // Action à définir
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: Theme.of(context).primaryColor),
                SizedBox(height: 16),
                Text(label, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
