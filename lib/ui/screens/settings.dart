import 'package:flutter/material.dart';
import 'package:niit/ui/widgets/app_bar.dart';

/// Palette et styles "Police"
class PoliceBrand {
  static const Color green = Color(0xFF0F7B3B);
  static const Color yellow = Color(0xFFF4C20D);
  static const Color red = Color(0xFFD93025);
  static const Color dark = Color(0xFF111111);
  static const Color light = Color(0xFFF7F7F7);

  static const Color primary = dark; // Accent sobre
  static const Color surface = Colors.white;

  static Gradient headerGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF111111), // noir
      Color(0xFF1E1E1E),
    ],
  );

  static BorderRadius radiusLg = BorderRadius.circular(18);
  static BorderRadius radiusSm = BorderRadius.circular(12);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- États switches ---
  bool _onDuty = true;
  bool _shareLiveLocation = true;
  bool _showRedZones = true;
  bool _wifiOnlySync = true;
  bool _nearbyIncidentNotif = true;
  bool _hqMessagesNotif = true;
  bool _updatesNotif = false;
  bool _usePinLock = false;
  bool _useBiometrics = false;
  double _sosSensitivity = 0.6;

  // --- Préférences simples ---
  String _mapLayer = "Standard";
  String _language = "Français";
  ThemeMode _themeMode = ThemeMode.system;

  // --- Infos compte (mock) ---
  final String _agentName = "Adj. NIANG Baye G.";
  final String _matricule = "PN-34821";
  final String _unite = "Compagnie Urbaine Dakar";

  void _pickLanguage() async {
    final r = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _BottomPicker(
        title: "Langue de l’application",
        items: const ["Français", "English", "العربية", "Wolof"],
        selected: _language,
      ),
    );
    if (r != null) setState(() => _language = r);
  }

  void _pickMapLayer() async {
    final r = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _BottomPicker(
        title: "Couche cartographique",
        items: const ["Standard", "Satellite", "Terrain", "Nocturne"],
        selected: _mapLayer,
      ),
    );
    if (r != null) setState(() => _mapLayer = r);
  }

  void _pickTheme() async {
    final r = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (_) => _ThemePicker(selected: _themeMode),
    );
    if (r != null) setState(() => _themeMode = r);
  }

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AccountPage(
          agentName: _agentName,
          matricule: _matricule,
          unite: _unite,
        ),
      ),
    );
  }

  void _openAbout() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _AboutPage()));
  }

  void _downloadOfflineMaps() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Téléchargement des cartes hors-ligne…")),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Cartes hors-ligne à jour ✅")));
  }

  void _syncNow() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _wifiOnlySync
              ? "Synchronisation (Wi-Fi uniquement)…"
              : "Synchronisation en cours…",
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Synchronisation réussie ✅")));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text(
          "Tu vas te déconnecter de l’application. Continuer ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).maybePop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Déconnecté.")));
            },
            child: const Text("Se déconnecter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
    );

    return Scaffold(
      backgroundColor: PoliceBrand.light,
      appBar: CustomAppBar(),
      body: CustomScrollView(
        slivers: [
          // ====== HEADER avec logo ======
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                gradient: PoliceBrand.headerGradient,
                borderRadius: PoliceBrand.radiusLg,
                image: const DecorationImage(
                  image: AssetImage('assets/img/police_logo.png'),
                  alignment: Alignment(1.2, -1.2),
                  opacity: 0.07,
                  fit: BoxFit.contain,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Image.asset('assets/img/police_logo.png'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Paramètres",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$_agentName • $_unite\nMatricule $_matricule",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _BadgeFlag(), // petit rappel couleurs drapeau
                ],
              ),
            ),
          ),

          // ====== CONTENU ======
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _Section(
                    title: "Profil & Compte",
                    accent: PoliceBrand.primary,
                    children: [
                      ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(_agentName),
                        subtitle: Text("Matricule $_matricule • $_unite"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openAccount,
                      ),
                      divider,
                    ],
                  ),

                  _Section(
                    title: "Paramètres opérationnels",
                    accent: PoliceBrand.green,
                    stripeColors: const [
                      PoliceBrand.green,
                      PoliceBrand.yellow,
                      PoliceBrand.red,
                    ],
                    children: [
                      SwitchListTile.adaptive(
                        activeColor: PoliceBrand.green,
                        title: const Text("En service (On duty)"),
                        subtitle: const Text(
                          "Active le statut opérationnel et la dispo radio",
                        ),
                        value: _onDuty,
                        onChanged: (v) => setState(() => _onDuty = v),
                      ),
                      SwitchListTile.adaptive(
                        activeColor: PoliceBrand.green,
                        title: const Text("Partage de position en patrouille"),
                        subtitle: const Text(
                          "Diffuse ta position en temps réel à ton unité",
                        ),
                        value: _shareLiveLocation,
                        onChanged: (v) =>
                            setState(() => _shareLiveLocation = v),
                      ),
                      ListTile(
                        title: const Text("Sensibilité du bouton SOS"),
                        subtitle: Text(
                          "Actuelle : ${(100 * _sosSensitivity).round()} % (glisser)",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Slider(
                          value: _sosSensitivity,
                          activeColor: PoliceBrand.red,
                          inactiveColor: PoliceBrand.red.withOpacity(.25),
                          onChanged: (v) => setState(() => _sosSensitivity = v),
                        ),
                      ),
                    ],
                  ),

                  _Section(
                    title: "Carte & géolocalisation",
                    accent: PoliceBrand.yellow,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.layers_outlined),
                        title: const Text("Couche de carte"),
                        subtitle: Text(_mapLayer),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickMapLayer,
                      ),
                      SwitchListTile.adaptive(
                        activeColor: PoliceBrand.red,
                        title: const Text("Afficher les zones rouges"),
                        subtitle: const Text(
                          "Zones à haut risque / alertes opérationnelles",
                        ),
                        value: _showRedZones,
                        onChanged: (v) => setState(() => _showRedZones = v),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.download_for_offline_outlined,
                        ),
                        title: const Text("Cartes hors-ligne"),
                        subtitle: const Text("Télécharger / mettre à jour"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _downloadOfflineMaps,
                      ),
                    ],
                  ),

                  _Section(
                    title: "Notifications",
                    accent: PoliceBrand.red,
                    children: [
                      SwitchListTile.adaptive(
                        activeColor: PoliceBrand.primary,
                        title: const Text("Incidents à proximité"),
                        value: _nearbyIncidentNotif,
                        onChanged: (v) =>
                            setState(() => _nearbyIncidentNotif = v),
                      ),
                      SwitchListTile.adaptive(
                        activeColor: PoliceBrand.primary,
                        title: const Text("Messages du Centre de Commandement"),
                        value: _hqMessagesNotif,
                        onChanged: (v) => setState(() => _hqMessagesNotif = v),
                      ),
                      SwitchListTile.adaptive(
                        activeColor: PoliceBrand.primary,
                        title: const Text("Mises à jour & bulletins"),
                        value: _updatesNotif,
                        onChanged: (v) => setState(() => _updatesNotif = v),
                      ),
                    ],
                  ),

                  _Section(
                    title: "Données & synchronisation",
                    accent: PoliceBrand.primary,
                    children: [
                      SwitchListTile.adaptive(
                        activeColor: PoliceBrand.green,
                        title: const Text("Synchroniser en Wi-Fi uniquement"),
                        value: _wifiOnlySync,
                        onChanged: (v) => setState(() => _wifiOnlySync = v),
                      ),
                      ListTile(
                        leading: const Icon(Icons.sync),
                        title: const Text("Synchroniser maintenant"),
                        onTap: _syncNow,
                      ),
                    ],
                  ),

                  _Section(
                    title: "App & affichage",
                    accent: PoliceBrand.primary,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.translate),
                        title: const Text("Langue"),
                        subtitle: Text(_language),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickLanguage,
                      ),
                      ListTile(
                        leading: const Icon(Icons.dark_mode_outlined),
                        title: const Text("Thème"),
                        subtitle: Text(
                          _themeMode == ThemeMode.light
                              ? "Clair"
                              : _themeMode == ThemeMode.dark
                              ? "Sombre"
                              : "Système",
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickTheme,
                      ),
                    ],
                  ),

                  _Section(
                    title: "Sécurité",
                    accent: PoliceBrand.primary,
                    children: [
                      SwitchListTile.adaptive(
                        activeColor: PoliceBrand.primary,
                        title: const Text("Verrouillage par code PIN"),
                        value: _usePinLock,
                        onChanged: (v) => setState(() => _usePinLock = v),
                      ),
                      SwitchListTile.adaptive(
                        activeColor: PoliceBrand.primary,
                        title: const Text("Déverrouillage biométrique"),
                        subtitle: const Text(
                          "Face ID / Touch ID si disponible",
                        ),
                        value: _useBiometrics,
                        onChanged: (v) => setState(() => _useBiometrics = v),
                      ),
                    ],
                  ),

                  _Section(
                    title: "À propos",
                    accent: PoliceBrand.primary,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text("À propos de l’application"),
                        onTap: _openAbout,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: PoliceBrand.radiusSm,
                          ),
                        ),
                        onPressed: _logout,
                        child: const Text("Se déconnecter"),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

/// Ruban tricolore inspiré du blason
class _BadgeFlag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: PoliceBrand.radiusSm,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _FlagStripe(color: PoliceBrand.green),
          _FlagStripe(color: PoliceBrand.yellow),
          _FlagStripe(color: PoliceBrand.red),
        ],
      ),
    );
  }
}

class _FlagStripe extends StatelessWidget {
  final Color color;
  const _FlagStripe({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 8, height: 40, color: color);
  }
}

// ---------- UI aides ----------

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color accent;
  final List<Color>? stripeColors;
  const _Section({
    required this.title,
    required this.children,
    required this.accent,
    this.stripeColors,
  });

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: PoliceBrand.dark,
          ),
        ),
        const Spacer(),
        if (stripeColors != null)
          Row(
            children: stripeColors!
                .map(
                  (c) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );

    final card = Card(
      color: PoliceBrand.surface,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: PoliceBrand.radiusLg),
      child: Column(children: children),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: titleRow,
          ),
          card,
        ],
      ),
    );
  }
}

class _BottomPicker extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selected;
  const _BottomPicker({
    required this.title,
    required this.items,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ...items.map(
              (e) => RadioListTile<String>(
                title: Text(e),
                value: e,
                groupValue: selected,
                onChanged: (v) => Navigator.pop(context, v),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final ThemeMode selected;
  const _ThemePicker({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Text("Thème", style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            RadioListTile<ThemeMode>(
              title: const Text("Système"),
              value: ThemeMode.system,
              groupValue: selected,
              onChanged: (v) => Navigator.pop(context, v),
            ),
            RadioListTile<ThemeMode>(
              title: const Text("Clair"),
              value: ThemeMode.light,
              groupValue: selected,
              onChanged: (v) => Navigator.pop(context, v),
            ),
            RadioListTile<ThemeMode>(
              title: const Text("Sombre"),
              value: ThemeMode.dark,
              groupValue: selected,
              onChanged: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------- Pages secondaires ----------

class _AccountPage extends StatelessWidget {
  final String agentName;
  final String matricule;
  final String unite;
  const _AccountPage({
    required this.agentName,
    required this.matricule,
    required this.unite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mon compte")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(agentName),
            subtitle: Text("Matricule $matricule\n$unite"),
            isThreeLine: true,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () {},
            child: const Text("Modifier mes informations"),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {},
            child: const Text("Changer le mot de passe"),
          ),
        ],
      ),
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Scaffold(
      appBar: AppBar(title: const Text("À propos")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Police Mobile",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text("Version 1.0.0 (build 1)", style: style),
            const SizedBox(height: 12),
            Text(
              "Application opérationnelle pour les forces de police : "
              "cartographie, SOS, incidents, messages du centre, et rapports.",
              style: style,
            ),
            const Spacer(),
            Text(
              "© ${DateTime.now().year} Ministère de l’Intérieur",
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:niit/ui/widgets/app_bar.dart';

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});

//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   // --- États switches ---
//   bool _onDuty = true;
//   bool _shareLiveLocation = true;
//   bool _showRedZones = true;
//   bool _wifiOnlySync = true;
//   bool _nearbyIncidentNotif = true;
//   bool _hqMessagesNotif = true;
//   bool _updatesNotif = false;
//   bool _usePinLock = false;
//   bool _useBiometrics = false;
//   double _sosSensitivity = 0.6;

//   // --- Préférences simples ---
//   String _mapLayer = "Standard";
//   String _language = "Français";
//   ThemeMode _themeMode = ThemeMode.system;

//   // --- Infos compte (mock) ---
//   final String _agentName = "Adj. Ndiaye A.";
//   final String _matricule = "PN-34821";
//   final String _unite = "Compagnie Urbaine Dakar";

//   void _pickLanguage() async {
//     final r = await showModalBottomSheet<String>(
//       context: context,
//       builder: (_) => _BottomPicker(
//         title: "Langue de l’application",
//         items: const ["Français", "English", "العربية", "Wolof"],
//         selected: _language,
//       ),
//     );
//     if (r != null) setState(() => _language = r);
//   }

//   void _pickMapLayer() async {
//     final r = await showModalBottomSheet<String>(
//       context: context,
//       builder: (_) => _BottomPicker(
//         title: "Couche cartographique",
//         items: const ["Standard", "Satellite", "Terrain", "Nocturne"],
//         selected: _mapLayer,
//       ),
//     );
//     if (r != null) setState(() => _mapLayer = r);
//   }

//   void _pickTheme() async {
//     final r = await showModalBottomSheet<ThemeMode>(
//       context: context,
//       builder: (_) => _ThemePicker(selected: _themeMode),
//     );
//     if (r != null) setState(() => _themeMode = r);
//   }

//   void _openAccount() {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => _AccountPage(
//           agentName: _agentName,
//           matricule: _matricule,
//           unite: _unite,
//         ),
//       ),
//     );
//   }

//   void _openAbout() {
//     Navigator.of(
//       context,
//     ).push(MaterialPageRoute(builder: (_) => const _AboutPage()));
//   }

//   void _downloadOfflineMaps() async {
//     // Action simulée
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Téléchargement des cartes hors-ligne…")),
//     );
//     await Future.delayed(const Duration(seconds: 2));
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("Cartes hors-ligne à jour ✅")));
//   }

//   void _syncNow() async {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           _wifiOnlySync
//               ? "Synchronisation (Wi-Fi uniquement)…"
//               : "Synchronisation en cours…",
//         ),
//       ),
//     );
//     await Future.delayed(const Duration(seconds: 2));
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("Synchronisation réussie ✅")));
//   }

//   void _logout() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Déconnexion"),
//         content: const Text(
//           "Tu vas te déconnecter de l’application. Continuer ?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Annuler"),
//           ),
//           FilledButton.tonal(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.of(context).maybePop();
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text("Déconnecté.")));
//             },
//             child: const Text("Se déconnecter"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: CustomAppBar(),
//       body: ListView(
//         padding: const EdgeInsets.all(12),
//         children: [
//           // --- Bloc compte / profil ---
//           _Section(
//             title: "Profil & Compte",
//             children: [
//               ListTile(
//                 leading: const CircleAvatar(child: Icon(Icons.person)),
//                 title: Text(_agentName),
//                 subtitle: Text("Matricule $_matricule • $_unite"),
//                 trailing: const Icon(Icons.chevron_right),
//                 onTap: _openAccount,
//               ),
//               const Divider(height: 1),
//             ],
//           ),

//           // --- Bloc opérationnel (police) ---
//           _Section(
//             title: "Paramètres opérationnels",
//             children: [
//               SwitchListTile(
//                 title: const Text("En service (On duty)"),
//                 subtitle: const Text(
//                   "Active le statut opérationnel et la dispo radio",
//                 ),
//                 value: _onDuty,
//                 onChanged: (v) => setState(() => _onDuty = v),
//               ),
//               SwitchListTile(
//                 title: const Text("Partage de position en patrouille"),
//                 subtitle: const Text(
//                   "Diffuse ta position en temps réel à ton unité",
//                 ),
//                 value: _shareLiveLocation,
//                 onChanged: (v) => setState(() => _shareLiveLocation = v),
//               ),
//               ListTile(
//                 title: const Text("Sensibilité du bouton SOS"),
//                 subtitle: Text(
//                   "Actuelle : ${(100 * _sosSensitivity).round()} % (glisser)",
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Slider(
//                   value: _sosSensitivity,
//                   onChanged: (v) => setState(() => _sosSensitivity = v),
//                 ),
//               ),
//             ],
//           ),

//           // --- Bloc carte ---
//           _Section(
//             title: "Carte & géolocalisation",
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.layers_outlined),
//                 title: const Text("Couche de carte"),
//                 subtitle: Text(_mapLayer),
//                 trailing: const Icon(Icons.chevron_right),
//                 onTap: _pickMapLayer,
//               ),
//               SwitchListTile(
//                 title: const Text("Afficher les zones rouges"),
//                 subtitle: const Text(
//                   "Zones à haut risque / alertes opérationnelles",
//                 ),
//                 value: _showRedZones,
//                 onChanged: (v) => setState(() => _showRedZones = v),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.download_for_offline_outlined),
//                 title: const Text("Cartes hors-ligne"),
//                 subtitle: const Text("Télécharger / mettre à jour"),
//                 trailing: const Icon(Icons.chevron_right),
//                 onTap: _downloadOfflineMaps,
//               ),
//             ],
//           ),

//           // --- Bloc notifications ---
//           _Section(
//             title: "Notifications",
//             children: [
//               SwitchListTile(
//                 title: const Text("Incidents à proximité"),
//                 value: _nearbyIncidentNotif,
//                 onChanged: (v) => setState(() => _nearbyIncidentNotif = v),
//               ),
//               SwitchListTile(
//                 title: const Text("Messages du Centre de Commandement"),
//                 value: _hqMessagesNotif,
//                 onChanged: (v) => setState(() => _hqMessagesNotif = v),
//               ),
//               SwitchListTile(
//                 title: const Text("Mises à jour & bulletins"),
//                 value: _updatesNotif,
//                 onChanged: (v) => setState(() => _updatesNotif = v),
//               ),
//             ],
//           ),

//           // --- Bloc synchronisation ---
//           _Section(
//             title: "Données & synchronisation",
//             children: [
//               SwitchListTile(
//                 title: const Text("Synchroniser en Wi-Fi uniquement"),
//                 value: _wifiOnlySync,
//                 onChanged: (v) => setState(() => _wifiOnlySync = v),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.sync),
//                 title: const Text("Synchroniser maintenant"),
//                 onTap: _syncNow,
//               ),
//             ],
//           ),

//           // --- Bloc apparence & langue ---
//           _Section(
//             title: "App & affichage",
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.translate),
//                 title: const Text("Langue"),
//                 subtitle: Text(_language),
//                 trailing: const Icon(Icons.chevron_right),
//                 onTap: _pickLanguage,
//               ),
//               ListTile(
//                 leading: const Icon(Icons.dark_mode_outlined),
//                 title: const Text("Thème"),
//                 subtitle: Text(
//                   _themeMode == ThemeMode.light
//                       ? "Clair"
//                       : _themeMode == ThemeMode.dark
//                       ? "Sombre"
//                       : "Système",
//                 ),
//                 trailing: const Icon(Icons.chevron_right),
//                 onTap: _pickTheme,
//               ),
//             ],
//           ),

//           // --- Bloc sécurité ---
//           _Section(
//             title: "Sécurité",
//             children: [
//               SwitchListTile(
//                 title: const Text("Verrouillage par code PIN"),
//                 value: _usePinLock,
//                 onChanged: (v) => setState(() => _usePinLock = v),
//               ),
//               SwitchListTile(
//                 title: const Text("Déverrouillage biométrique"),
//                 subtitle: const Text("Face ID / Touch ID si disponible"),
//                 value: _useBiometrics,
//                 onChanged: (v) => setState(() => _useBiometrics = v),
//               ),
//             ],
//           ),

//           // --- À propos & déconnexion ---
//           _Section(
//             title: "À propos",
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.info_outline),
//                 title: const Text("À propos de l’application"),
//                 onTap: _openAbout,
//               ),
//               const SizedBox(height: 8),
//               FilledButton.tonal(
//                 style: FilledButton.styleFrom(
//                   backgroundColor: theme.colorScheme.errorContainer,
//                   foregroundColor: theme.colorScheme.onErrorContainer,
//                 ),
//                 onPressed: _logout,
//                 child: const Text("Se déconnecter"),
//               ),
//               const SizedBox(height: 16),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ---------- UI aides ----------

// class _Section extends StatelessWidget {
//   final String title;
//   final List<Widget> children;
//   const _Section({required this.title, required this.children});

//   @override
//   Widget build(BuildContext context) {
//     final card = Card(
//       clipBehavior: Clip.antiAlias,
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Column(children: children),
//     );

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
//             child: Text(
//               title,
//               style: Theme.of(
//                 context,
//               ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
//             ),
//           ),
//           card,
//         ],
//       ),
//     );
//   }
// }

// class _BottomPicker extends StatelessWidget {
//   final String title;
//   final List<String> items;
//   final String selected;
//   const _BottomPicker({
//     required this.title,
//     required this.items,
//     required this.selected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Material(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 6),
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.black26,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16.0,
//                 vertical: 12,
//               ),
//               child: Row(
//                 children: [
//                   Text(title, style: Theme.of(context).textTheme.titleMedium),
//                   const Spacer(),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//             ),
//             ...items.map(
//               (e) => RadioListTile<String>(
//                 title: Text(e),
//                 value: e,
//                 groupValue: selected,
//                 onChanged: (v) => Navigator.pop(context, v),
//               ),
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ThemePicker extends StatelessWidget {
//   final ThemeMode selected;
//   const _ThemePicker({required this.selected});

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Material(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 6),
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.black26,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16.0,
//                 vertical: 12,
//               ),
//               child: Row(
//                 children: [
//                   Text("Thème", style: Theme.of(context).textTheme.titleMedium),
//                   const Spacer(),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//             ),
//             RadioListTile<ThemeMode>(
//               title: const Text("Système"),
//               value: ThemeMode.system,
//               groupValue: selected,
//               onChanged: (v) => Navigator.pop(context, v),
//             ),
//             RadioListTile<ThemeMode>(
//               title: const Text("Clair"),
//               value: ThemeMode.light,
//               groupValue: selected,
//               onChanged: (v) => Navigator.pop(context, v),
//             ),
//             RadioListTile<ThemeMode>(
//               title: const Text("Sombre"),
//               value: ThemeMode.dark,
//               groupValue: selected,
//               onChanged: (v) => Navigator.pop(context, v),
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ---------- Pages secondaires (simples) ----------

// class _AccountPage extends StatelessWidget {
//   final String agentName;
//   final String matricule;
//   final String unite;
//   const _AccountPage({
//     required this.agentName,
//     required this.matricule,
//     required this.unite,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Mon compte")),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           ListTile(
//             leading: const CircleAvatar(child: Icon(Icons.person)),
//             title: Text(agentName),
//             subtitle: Text("Matricule $matricule\n$unite"),
//             isThreeLine: true,
//           ),
//           const SizedBox(height: 12),
//           FilledButton.tonal(
//             onPressed: () {},
//             child: const Text("Modifier mes informations"),
//           ),
//           const SizedBox(height: 8),
//           FilledButton.tonal(
//             onPressed: () {},
//             child: const Text("Changer le mot de passe"),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AboutPage extends StatelessWidget {
//   const _AboutPage();

//   @override
//   Widget build(BuildContext context) {
//     final style = Theme.of(context).textTheme.bodyMedium;
//     return Scaffold(
//       appBar: AppBar(title: const Text("À propos")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Police Mobile",
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 4),
//             Text("Version 1.0.0 (build 1)", style: style),
//             const SizedBox(height: 12),
//             Text(
//               "Application opérationnelle pour les forces de police : "
//               "cartographie, SOS, incidents, messages du centre, et rapports.",
//               style: style,
//             ),
//             const Spacer(),
//             Text(
//               "© ${DateTime.now().year} Ministère de l’Intérieur",
//               style: style,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
