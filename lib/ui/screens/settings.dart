import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  final TextEditingController nameCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: cs.tertiaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: darkMode,
            title: const Text('Mode sombre (démo locale)'),
            onChanged: (v) => setState(() => darkMode = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Votre nom',
              hintText: 'Ex: Aby',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final snack = SnackBar(content: Text('Sauvegardé (démo) : ${nameCtrl.text}'));
              ScaffoldMessenger.of(context).showSnackBar(snack);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
