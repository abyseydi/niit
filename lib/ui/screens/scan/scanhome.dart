import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:niit/ui/screens/settings.dart';
import 'package:niit/ui/widgets/app_bar.dart'; // ton AppBar custom

class PlateRecognitionScreen extends StatefulWidget {
  const PlateRecognitionScreen({super.key});
  @override
  State<PlateRecognitionScreen> createState() => _PlateRecognitionScreenState();
}

class _PlateRecognitionScreenState extends State<PlateRecognitionScreen> {
  final _picker = ImagePicker();
  late final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  final _plateCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  File? _image;

  final Map<String, VehicleInfo> _assigned = {};
  final List<String> _history = [];
  final _rng = Random();

  final List<_Combo> _baseCombos = const [
    _Combo(VehicleStatus.ok, true),
    _Combo(VehicleStatus.ok, false),
    _Combo(VehicleStatus.recherche, true),
    _Combo(VehicleStatus.recherche, false),
    _Combo(VehicleStatus.vole, false),
    _Combo(VehicleStatus.non_assure, false),
    _Combo(VehicleStatus.vole, true),
    _Combo(VehicleStatus.ok, true),
    _Combo(VehicleStatus.recherche, true),
  ];
  late List<_Combo> _comboQueue = [];

  final List<RegExp> _platePatterns = [
    RegExp(r'\b[A-Z]{1,3}[-\s]?\d{2,4}[-\s]?[A-Z]{0,3}\b'),
    RegExp(r'\b[A-Z0-9\-]{5,10}\b'),
  ];

  @override
  void initState() {
    super.initState();
    _reshuffleCombos();
  }

  void _reshuffleCombos() {
    _comboQueue = List<_Combo>.from(_baseCombos)..shuffle(_rng);
  }

  @override
  void dispose() {
    _recognizer.close();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _addSinglePlate() async {
    FocusScope.of(context).unfocus();
    final raw = _plateCtrl.text.trim().toUpperCase();
    if (raw.isEmpty) {
      setState(() => _error = "Merci de saisir une plaque (ex: DK-1234-AB).");
      return;
    }
    final plate = _normalizePlate(raw);
    _assignIfNeeded(plate);
    setState(() {
      _error = null;
      _plateCtrl.clear();
    });
    _showInfoForPlate(_assigned[plate]!);
  }

  Future<void> _openBulkAdder() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _BulkAddSheet(),
    );
    if (result == null || result.isEmpty) return;

    for (final raw in result) {
      final plate = _normalizePlate(raw.toUpperCase());
      _assignIfNeeded(plate);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    setState(() => _error = null);
  }

  Future<void> _pickAndRecognize(ImageSource source) async {
    setState(() {
      _error = null;
      _image = null;
    });

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 95);
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _image = file;
        _loading = true;
      });

      VehicleInfo? infoToShow;

      final inputImage = InputImage.fromFile(file);
      final ocrTask = () async {
        final result = await _recognizer.processImage(inputImage);

        final buffer = StringBuffer();
        for (final block in result.blocks) {
          for (final line in block.lines) {
            buffer.writeln(line.text);
          }
        }
        final ocrText = buffer.toString().toUpperCase();

        final normalized = _normalizeOcr(ocrText);
        final candidates = _extractPlateCandidates(normalized);
        final best = _pickBestCandidate(candidates);

        if (best == null) {
          _error = "Aucune plaque détectée.";
          return;
        }

        final plate = best.$1;
        _assignIfNeeded(plate);
        infoToShow = _assigned[plate];
      }();

      final minimumDelay = Future.delayed(const Duration(seconds: 3));

      await Future.wait([ocrTask, minimumDelay]);

      if (!mounted) return;
      setState(() => _loading = false);

      if (infoToShow != null) {
        _showInfoForPlate(infoToShow!);
      } else if (_error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_error!)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Erreur OCR: $e";
      });
    }
  }

  void _assignIfNeeded(String plate) {
    if (_assigned.containsKey(plate)) {
      _history.remove(plate);
      _history.insert(0, plate);
      return;
    }

    if (_comboQueue.isEmpty) _reshuffleCombos();
    final combo = _comboQueue.removeAt(0);
    final info = _buildInfoFromCombo(plate, combo);

    _assigned[plate] = info;
    _history.insert(0, plate);
  }

  VehicleInfo _buildInfoFromCombo(String plate, _Combo c) {
    DateTime? start;
    DateTime? end;

    if (c.assurance) {
      final startOffset = _rng.nextInt(61);
      start = DateTime.now().subtract(Duration(days: startOffset));
      final months = 10 + _rng.nextInt(4);
      end = DateTime(start.year, start.month + months, start.day);
    } else {
      if (_rng.nextBool()) {
        start = null;
        end = null;
      } else {
        final endOffset = 5 + _rng.nextInt(60);
        end = DateTime.now().subtract(Duration(days: endOffset));
        start = end.subtract(const Duration(days: 365));
      }
    }

    return VehicleInfo(
      plate: plate,
      status: c.status,
      assurance: c.assurance,
      assuranceStart: start,
      assuranceEnd: end,
    );
  }

  String _normalizeOcr(String s) {
    final up = s.toUpperCase();
    return up.replaceAll(RegExp(r'[·•]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizePlate(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
  }

  List<String> _extractPlateCandidates(String normalized) {
    final List<String> res = [];
    for (final rgx in _platePatterns) {
      for (final m in rgx.allMatches(normalized)) {
        var cand = m.group(0)!;
        cand = cand.replaceAll(RegExp(r'\s+'), '-');
        cand = cand.replaceAll(RegExp(r'-{2,}'), '-');
        res.add(cand);
      }
    }
    final seen = <String>{};
    final uniq = <String>[];
    for (final c in res) {
      if (seen.add(c)) uniq.add(c);
    }
    return uniq;
  }

  (String, double)? _pickBestCandidate(List<String> candidates) {
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.length.compareTo(a.length));
    final best = candidates.first;
    return (best, 0.9);
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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
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
                              "Contrôle des véhicules",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const _BadgeFlag(),
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
                      // ---- Section "Saisie & Scan"
                      _Section(
                        title: "Saisie ou Scan",
                        accent: PoliceBrand.primary,
                        children: [
                          // Saisie
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                            child: TextField(
                              controller: _plateCtrl,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Z0-9\-]'),
                                ),
                                _UpperCaseTextFormatter(),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Plaque du véhicule',
                                hintText: 'Ex: DK-1234-AB',
                                // prefixIcon: const Icon(Icons.onetwothree), // ❌ supprimé
                                border: OutlineInputBorder(
                                  borderRadius: PoliceBrand.radiusSm,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              onSubmitted: (_) => _addSinglePlate(),
                            ),
                          ),

                          // Actions
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: PoliceBrand.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: PoliceBrand.radiusSm,
                                      ),
                                    ),
                                    onPressed: _loading
                                        ? null
                                        : _addSinglePlate,
                                    label: const Text('Analyser'),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                const Spacer(),
                                IconButton.filledTonal(
                                  onPressed: _loading
                                      ? null
                                      : () => _pickAndRecognize(
                                          ImageSource.camera,
                                        ),
                                  icon: const Icon(Icons.photo_camera),
                                  tooltip: 'Caméra',
                                ),
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  onPressed: _loading
                                      ? null
                                      : () => _pickAndRecognize(
                                          ImageSource.gallery,
                                        ),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                  tooltip: 'Galerie',
                                ),
                              ],
                            ),
                          ),

                          if (_loading) const LinearProgressIndicator(),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 12,
                                bottom: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Erreur: $_error',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // ---- Section "Dernière image"
                      if (_image != null)
                        _Section(
                          title: "Dernière image",
                          accent: PoliceBrand.primary,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 10,
                              child: ClipRRect(
                                borderRadius: PoliceBrand.radiusLg,
                                child: Image.file(_image!, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),

                      // ---- Section "Véhicules contrôlés"
                      _Section(
                        title: "Véhicules contrôlés",
                        accent: PoliceBrand.green,
                        stripeColors: const [
                          PoliceBrand.green,
                          PoliceBrand.yellow,
                          PoliceBrand.red,
                        ],
                        children: [
                          if (_history.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "Aucun véhicule. Veuillez ajouter une plaque (saisie) ou scanner via Caméra/Galerie.",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            )
                          else
                            ..._history.map((plate) {
                              final info = _assigned[plate]!;
                              return Column(
                                children: [
                                  _VehicleCard(
                                    info: info,
                                    onOpen: () => _showInfoForPlate(info),
                                    onDelete: () {
                                      setState(() {
                                        _assigned.remove(plate);
                                        _history.remove(plate);
                                      });
                                    },
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                ],
                              );
                            }).toList(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                FilledButton.tonal(
                                  onPressed: () {
                                    setState(() {
                                      _assigned.clear();
                                      _history.clear();
                                      _reshuffleCombos();
                                      _error = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Réinitialisation effectuée',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Réinitialiser'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_loading) const _LoadingOverlay(message: "Analyse de la plaque…"),
        ],
      ),
    );
  }

  // ---- Fiche détail véhicule (bottom sheet)
  void _showInfoForPlate(VehicleInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final color = _statusColor(info.status);
        final icon = _statusIcon(info.status);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      info.plate,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _Pill(
                    // icon: ,
                    label: _statusLabel(info.status).toUpperCase(),
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    // icon: info.assurance ? Icons.shield : Icons.shield_outlined,
                    label: 'Assurance : ${info.assurance ? 'OUI' : 'NON'}',
                    color: info.assurance ? PoliceBrand.green : PoliceBrand.red,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.today, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Début: ${_fmtDate(info.assuranceStart)}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.event, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Fin: ${_fmtDate(info.assuranceEnd)}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Constat sauvegardé pour ${info.plate}',
                            ),
                          ),
                        );
                      },
                      child: const Text('Enregistrer constat'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  // ---- Helpers visuels cohérents Settings
  Color _statusColor(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.vole:
        return PoliceBrand.red;
      case VehicleStatus.recherche:
        return const Color(0xFFEF6C00);
      case VehicleStatus.ok:
        return PoliceBrand.green;
      case VehicleStatus.non_assure:
        return const Color(0xFFFB8C00);
    }
  }

  IconData _statusIcon(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.vole:
        return Icons.report;
      case VehicleStatus.recherche:
        return Icons.search;
      case VehicleStatus.ok:
        return Icons.verified;
      case VehicleStatus.non_assure:
        return Icons.shield_outlined;
    }
  }

  String _statusLabel(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.vole:
        return 'Volé';
      case VehicleStatus.recherche:
        return 'Recherché';
      case VehicleStatus.ok:
        return 'OK';
      case VehicleStatus.non_assure:
        return 'Non assuré';
    }
  }

  String _fmtDate(DateTime? d) => (d == null)
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _VehicleCard extends StatelessWidget {
  final VehicleInfo info;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  const _VehicleCard({
    required this.info,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(info.status);
    final icon = _statusIcon(info.status);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        info.plate,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                // icon: icon,
                label: _statusLabel(info.status).toUpperCase(),
                color: color,
              ),
              _Pill(
                // icon: info.assurance ? Icons.shield : Icons.shield_outlined,
                label: 'Assurance : ${info.assurance ? 'OUI' : 'NON'}',
                color: info.assurance ? PoliceBrand.green : PoliceBrand.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.today, size: 16),
              const SizedBox(width: 4),
              Text('Début: ${_fmtDate(info.assuranceStart)}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.event, size: 16),
              const SizedBox(width: 4),
              Text('Fin: ${_fmtDate(info.assuranceEnd)}'),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Voir',
            icon: const Icon(Icons.chevron_right),
            onPressed: onOpen,
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  static Color _statusColor(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.vole:
        return PoliceBrand.red;
      case VehicleStatus.recherche:
        return const Color(0xFFEF6C00);
      case VehicleStatus.ok:
        return PoliceBrand.green;
      case VehicleStatus.non_assure:
        return const Color(0xFFFB8C00);
    }
  }

  static IconData _statusIcon(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.vole:
        return Icons.report;
      case VehicleStatus.recherche:
        return Icons.search;
      case VehicleStatus.ok:
        return Icons.verified;
      case VehicleStatus.non_assure:
        return Icons.shield_outlined;
    }
  }

  static String _statusLabel(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.vole:
        return 'Volé';
      case VehicleStatus.recherche:
        return 'Recherché';
      case VehicleStatus.ok:
        return 'OK';
      case VehicleStatus.non_assure:
        return 'Non assuré';
    }
  }

  static String _fmtDate(DateTime? d) => (d == null)
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _BulkAddSheet extends StatefulWidget {
  const _BulkAddSheet();

  @override
  State<_BulkAddSheet> createState() => _BulkAddSheetState();
}

class _BulkAddSheetState extends State<_BulkAddSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Material(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  minLines: 4,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-\s,]')),
                    _UpperCaseTextFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Ex:\nDK-1234-AB, AA-9876-CD\nZF-2244-GH\n... ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          final raw = _ctrl.text.trim().toUpperCase();
                          final items = raw
                              .split(RegExp(r'[,\n]'))
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          Navigator.pop(context, items);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Ajouter"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeFlag extends StatelessWidget {
  const _BadgeFlag();
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

class _Pill extends StatelessWidget {
  // final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

enum VehicleStatus { vole, recherche, ok, non_assure }

class VehicleInfo {
  final String plate;
  final VehicleStatus status;
  final bool assurance;
  final DateTime? assuranceStart;
  final DateTime? assuranceEnd;

  VehicleInfo({
    required this.plate,
    required this.status,
    required this.assurance,
    this.assuranceStart,
    this.assuranceEnd,
  });
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _Combo {
  final VehicleStatus status;
  final bool assurance;
  const _Combo(this.status, this.assurance);
}

class _LoadingOverlay extends StatelessWidget {
  final String? message;
  const _LoadingOverlay({this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.25)),
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: PoliceBrand.radiusLg,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PoliceSpinner(size: 86),
                  const SizedBox(height: 12),
                  Text(
                    message ?? "Chargement…",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: PoliceBrand.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Merci de patienter",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoliceSpinner extends StatefulWidget {
  final double size;
  const _PoliceSpinner({this.size = 72});

  @override
  State<_PoliceSpinner> createState() => _PoliceSpinnerState();
}

class _PoliceSpinnerState extends State<_PoliceSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Transform.rotate(
                angle: _ctrl.value * 6.28318, // 2π
                child: CustomPaint(
                  size: Size.square(s),
                  painter: _RingPainter(),
                ),
              );
            },
          ),
          Container(
            width: s * 0.55,
            height: s * 0.55,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/img/police_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.10;
    final rect = Offset.zero & size;
    final start = -90.0 * (3.14159 / 180.0);
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 6.28318,
      colors: const [
        PoliceBrand.green,
        PoliceBrand.yellow,
        PoliceBrand.red,
        PoliceBrand.green,
      ],
      stops: const [0.0, 0.33, 0.66, 1.0],
    );

    final paintBg = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawArc(
      Rect.fromLTWH(
        stroke / 2,
        stroke / 2,
        size.width - stroke,
        size.height - stroke,
      ),
      0,
      6.28318,
      false,
      paintBg,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        stroke / 2,
        stroke / 2,
        size.width - stroke,
        size.height - stroke,
      ),
      start,
      6.28318 * 0.75,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}
