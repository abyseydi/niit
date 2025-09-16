// // // // // // import 'dart:io';
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:image_picker/image_picker.dart';
// // // // // // import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// // // // // // class PlateRecognitionScreen extends StatefulWidget {
// // // // // //   const PlateRecognitionScreen({super.key});

// // // // // //   @override
// // // // // //   State<PlateRecognitionScreen> createState() => _PlateRecognitionScreenState();
// // // // // // }

// // // // // // class _PlateRecognitionScreenState extends State<PlateRecognitionScreen> {
// // // // // //   final _picker = ImagePicker();
// // // // // //   File? _image;
// // // // // //   bool _loading = false;

// // // // // //   // OCR brut
// // // // // //   String _text = '';

// // // // // //   // Sortie principale
// // // // // //   String? _plate;
// // // // // //   double? _confidence; // heuristique locale 0..1

// // // // // //   // Infos véhicule (à afficher après scan)
// // // // // //   VehicleInfo? _vehicleInfo;

// // // // // //   String? _error;

// // // // // //   late final TextRecognizer _recognizer = TextRecognizer(
// // // // // //     script: TextRecognitionScript.latin,
// // // // // //   );

// // // // // //   // ========= Flux principal : prendre/choisir, OCR, extraire plaque, charger infos =========
// // // // // //   Future<void> _pickAndRecognize(ImageSource source) async {
// // // // // //     setState(() {
// // // // // //       _loading = true;
// // // // // //       _error = null;
// // // // // //       _text = '';
// // // // // //       _plate = null;
// // // // // //       _confidence = null;
// // // // // //       _vehicleInfo = null;
// // // // // //     });

// // // // // //     try {
// // // // // //       final picked = await _picker.pickImage(source: source, imageQuality: 95);
// // // // // //       if (picked == null) {
// // // // // //         setState(() => _loading = false);
// // // // // //         return;
// // // // // //       }

// // // // // //       final file = File(picked.path);
// // // // // //       setState(() => _image = file);

// // // // // //       final inputImage = InputImage.fromFile(file);
// // // // // //       final result = await _recognizer.processImage(inputImage);

// // // // // //       final buffer = StringBuffer();
// // // // // //       for (final block in result.blocks) {
// // // // // //         for (final line in block.lines) {
// // // // // //           buffer.writeln(line.text);
// // // // // //         }
// // // // // //       }
// // // // // //       final ocrText = buffer.toString().trim();

// // // // // //       final normalized = _normalizeOcr(ocrText);
// // // // // //       final candidates = _extractPlateCandidates(normalized);
// // // // // //       final best = _pickBestCandidate(candidates);

// // // // // //       String? plate;
// // // // // //       double? conf;
// // // // // //       if (best != null) {
// // // // // //         plate = best.$1;
// // // // // //         conf = best.$2;
// // // // // //       }

// // // // // //       setState(() {
// // // // // //         _text = ocrText;
// // // // // //         _plate = plate;
// // // // // //         _confidence = conf;
// // // // // //       });

// // // // // //       // Charger les infos véhicule (mock pour l’instant)
// // // // // //       if (plate != null) {
// // // // // //         final info = await _loadVehicleInfo(plate);
// // // // // //         setState(() => _vehicleInfo = info);
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       setState(() => _error = e.toString());
// // // // // //     } finally {
// // // // // //       setState(() => _loading = false);
// // // // // //     }
// // // // // //   }

// // // // // //   // ========= MOCK: remplace ceci par tes vrais appels API =========
// // // // // //   Future<VehicleInfo> _loadVehicleInfo(String plate) async {
// // // // // //     // TODO: remplacer par un appel réseau vers ton SI:
// // // // // //     // final info = await ApiVehicules.getByPlate(plate);
// // // // // //     // return info;

// // // // // //     // ---- SIMULATION intelligible ----
// // // // // //     // Tu peux affiner la logique ici selon tes jeux de test
// // // // // //     await Future<void>.delayed(
// // // // // //       const Duration(milliseconds: 300),
// // // // // //     ); // petite latence

// // // // // //     if (plate.contains('VOLE')) {
// // // // // //       return VehicleInfo(
// // // // // //         plate: plate,
// // // // // //         status: VehicleStatus.vole,
// // // // // //         assurance: false,
// // // // // //         assuranceStart: null,
// // // // // //         assuranceEnd: null,
// // // // // //       );
// // // // // //     }
// // // // // //     if (plate.contains('NSA') || plate.contains('NONASSURE')) {
// // // // // //       return VehicleInfo(
// // // // // //         plate: plate,
// // // // // //         status: VehicleStatus.non_assure,
// // // // // //         assurance: false,
// // // // // //         assuranceStart: null,
// // // // // //         assuranceEnd: null,
// // // // // //       );
// // // // // //     }
// // // // // //     if (plate.contains('SRCH') || plate.contains('WANTED')) {
// // // // // //       return VehicleInfo(
// // // // // //         plate: plate,
// // // // // //         status: VehicleStatus.recherche,
// // // // // //         assurance: true,
// // // // // //         assuranceStart: DateTime.now().subtract(const Duration(days: 30)),
// // // // // //         assuranceEnd: DateTime.now().add(const Duration(days: 335)),
// // // // // //       );
// // // // // //     }
// // // // // //     // Par défaut : OK + assuré un an
// // // // // //     final start = DateTime.now().subtract(const Duration(days: 15));
// // // // // //     final end = DateTime(start.year + 1, start.month, start.day);
// // // // // //     return VehicleInfo(
// // // // // //       plate: plate,
// // // // // //       status: VehicleStatus.ok,
// // // // // //       assurance: true,
// // // // // //       assuranceStart: start,
// // // // // //       assuranceEnd: end,
// // // // // //     );
// // // // // //   }

// // // // // //   // ========= Utilitaires OCR/Heuristique =========
// // // // // //   String _normalizeOcr(String s) {
// // // // // //     final up = s.toUpperCase();
// // // // // //     return up.replaceAll(RegExp(r'[·•]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
// // // // // //   }

// // // // // //   final List<RegExp> _platePatterns = [
// // // // // //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{3,4}[-\s]?[A-Z]{1,3}\b'),
// // // // // //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{2,4}[-\s]?[A-Z]{1,3}\b'),
// // // // // //     RegExp(r'\b\d{2,4}[-\s]?[A-Z]{1,3}[-\s]?\d{2,4}\b'),
// // // // // //     RegExp(r'\b[A-Z0-9]{6,10}\b'),
// // // // // //   ];

// // // // // //   List<String> _extractPlateCandidates(String normalized) {
// // // // // //     final List<String> res = [];
// // // // // //     for (final rgx in _platePatterns) {
// // // // // //       for (final m in rgx.allMatches(normalized)) {
// // // // // //         var cand = m.group(0)!;
// // // // // //         cand = cand.replaceAll(RegExp(r'\s+'), '-');
// // // // // //         cand = cand.replaceAll(RegExp(r'-{2,}'), '-');
// // // // // //         res.add(cand);
// // // // // //       }
// // // // // //     }
// // // // // //     final seen = <String>{};
// // // // // //     final uniq = <String>[];
// // // // // //     for (final c in res) {
// // // // // //       if (seen.add(c)) uniq.add(c);
// // // // // //     }
// // // // // //     return uniq;
// // // // // //   }

// // // // // //   (String, double)? _pickBestCandidate(List<String> candidates) {
// // // // // //     if (candidates.isEmpty) return null;

// // // // // //     double scoreOf(String c) {
// // // // // //       final s = c.replaceAll('-', '');
// // // // // //       if (s.length < 5 || s.length > 10) return 0.1;

// // // // // //       final letters = RegExp(r'[A-Z]').allMatches(s).length;
// // // // // //       final digits = RegExp(r'\d').allMatches(s).length;
// // // // // //       double score = 0.5;

// // // // // //       if (letters > 0 && digits > 0) score += 0.2;
// // // // // //       if (c.contains('-')) score += 0.1;
// // // // // //       if (RegExp(r'(.)\1{2,}').hasMatch(s)) score -= 0.2;
// // // // // //       if (s.length >= 7 && s.length <= 8) score += 0.1;

// // // // // //       return score.clamp(0, 1);
// // // // // //     }

// // // // // //     String best = candidates.first;
// // // // // //     double bestScore = scoreOf(best);
// // // // // //     for (final c in candidates.skip(1)) {
// // // // // //       final sc = scoreOf(c);
// // // // // //       if (sc > bestScore) {
// // // // // //         best = c;
// // // // // //         bestScore = sc;
// // // // // //       }
// // // // // //     }
// // // // // //     return (best, bestScore);
// // // // // //   }

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     _recognizer.close();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   // ========= UI =========
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       appBar: AppBar(title: const Text('Scan véhicules • OCR local')),
// // // // // //       body: Padding(
// // // // // //         padding: const EdgeInsets.all(16),
// // // // // //         child: Column(
// // // // // //           children: [
// // // // // //             // Aperçu image
// // // // // //             if (_image != null)
// // // // // //               AspectRatio(
// // // // // //                 aspectRatio: 1.6,
// // // // // //                 child: ClipRRect(
// // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // //                   child: Image.file(_image!, fit: BoxFit.cover),
// // // // // //                 ),
// // // // // //               )
// // // // // //             else
// // // // // //               Container(
// // // // // //                 height: 180,
// // // // // //                 decoration: BoxDecoration(
// // // // // //                   border: Border.all(color: Colors.black12),
// // // // // //                   borderRadius: BorderRadius.circular(12),
// // // // // //                 ),
// // // // // //                 child: const Center(
// // // // // //                   child: Text(
// // // // // //                     'Prendre une photo ou choisir une image de la plaque',
// // // // // //                     textAlign: TextAlign.center,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             const SizedBox(height: 12),

// // // // // //             // Boutons source
// // // // // //             Row(
// // // // // //               children: [
// // // // // //                 Expanded(
// // // // // //                   child: ElevatedButton.icon(
// // // // // //                     onPressed: _loading
// // // // // //                         ? null
// // // // // //                         : () => _pickAndRecognize(ImageSource.camera),
// // // // // //                     icon: const Icon(Icons.photo_camera),
// // // // // //                     label: const Text('Caméra'),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(width: 12),
// // // // // //                 Expanded(
// // // // // //                   child: OutlinedButton.icon(
// // // // // //                     onPressed: _loading
// // // // // //                         ? null
// // // // // //                         : () => _pickAndRecognize(ImageSource.gallery),
// // // // // //                     icon: const Icon(Icons.photo_library),
// // // // // //                     label: const Text('Galerie'),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),

// // // // // //             const SizedBox(height: 12),
// // // // // //             if (_loading) const LinearProgressIndicator(),
// // // // // //             if (_error != null)
// // // // // //               Padding(
// // // // // //                 padding: const EdgeInsets.only(top: 8.0),
// // // // // //                 child: Text(
// // // // // //                   'Erreur: $_error',
// // // // // //                   style: const TextStyle(color: Colors.red),
// // // // // //                 ),
// // // // // //               ),

// // // // // //             // ----- Panneau synthèse véhicule -----
// // // // // //             _vehicleInfoCard(),

// // // // // //             // (Optionnel) OCR brut pour contrôle
// // // // // //             const SizedBox(height: 8),
// // // // // //             // Expanded(
// // // // // //             //   child: Container(
// // // // // //             //     padding: const EdgeInsets.all(12),
// // // // // //             //     decoration: BoxDecoration(
// // // // // //             //       border: Border.all(color: Colors.black12),
// // // // // //             //       borderRadius: BorderRadius.circular(8),
// // // // // //             //     ),
// // // // // //             //     child: SingleChildScrollView(
// // // // // //             //       child: SelectableText(
// // // // // //             //         _text.isEmpty ? '— Résultat OCR —' : _text,
// // // // // //             //         style: const TextStyle(fontSize: 16),
// // // // // //             //       ),
// // // // // //             //     ),
// // // // // //             //   ),
// // // // // //             // ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   Widget _vehicleInfoCard() {
// // // // // //     if (_loading) return const SizedBox.shrink();
// // // // // //     if (_plate == null && _vehicleInfo == null) return const SizedBox.shrink();

// // // // // //     final now = DateTime.now();
// // // // // //     final confPct = _confidence != null
// // // // // //         ? (_confidence! * 100).toStringAsFixed(0)
// // // // // //         : null;
// // // // // //     final info = _vehicleInfo;

// // // // // //     Color statusColor = Colors.grey;
// // // // // //     IconData statusIcon = Icons.help_outline;
// // // // // //     String statusLabel = 'Inconnu';

// // // // // //     if (info != null) {
// // // // // //       switch (info.status) {
// // // // // //         case VehicleStatus.vole:
// // // // // //           statusColor = Colors.red.shade600;
// // // // // //           statusIcon = Icons.report;
// // // // // //           statusLabel = 'volé';
// // // // // //           break;
// // // // // //         case VehicleStatus.non_assure:
// // // // // //           statusColor = Colors.orange.shade700;
// // // // // //           statusIcon = Icons.shield;
// // // // // //           statusLabel = 'non assuré';
// // // // // //           break;
// // // // // //         case VehicleStatus.recherche:
// // // // // //           statusColor = Colors.deepOrange.shade700;
// // // // // //           statusIcon = Icons.search;
// // // // // //           statusLabel = 'recherché';
// // // // // //           break;
// // // // // //         case VehicleStatus.ok:
// // // // // //           statusColor = Colors.green.shade600;
// // // // // //           statusIcon = Icons.verified;
// // // // // //           statusLabel = 'ok';
// // // // // //           break;
// // // // // //       }
// // // // // //     }

// // // // // //     return Card(
// // // // // //       elevation: 0,
// // // // // //       margin: const EdgeInsets.only(top: 12),
// // // // // //       shape: RoundedRectangleBorder(
// // // // // //         borderRadius: BorderRadius.circular(12),
// // // // // //         side: const BorderSide(color: Colors.black12),
// // // // // //       ),
// // // // // //       child: Padding(
// // // // // //         padding: const EdgeInsets.all(12),
// // // // // //         child: Column(
// // // // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //           children: [
// // // // // //             // En-tête
// // // // // //             Row(
// // // // // //               children: [
// // // // // //                 const Icon(Icons.directions_car, size: 26),
// // // // // //                 const SizedBox(width: 8),
// // // // // //                 Expanded(
// // // // // //                   child: Text(
// // // // // //                     _plate ?? '—',
// // // // // //                     style: const TextStyle(
// // // // // //                       fontSize: 22,
// // // // // //                       fontWeight: FontWeight.bold,
// // // // // //                       letterSpacing: 1.1,
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 if (confPct != null) Chip(label: Text('Confiance $confPct%')),
// // // // // //               ],
// // // // // //             ),
// // // // // //             const SizedBox(height: 10),

// // // // // //             // Ligne statut + assurance
// // // // // //             Wrap(
// // // // // //               spacing: 10,
// // // // // //               runSpacing: 10,
// // // // // //               crossAxisAlignment: WrapCrossAlignment.center,
// // // // // //               children: [
// // // // // //                 _StatusChip(
// // // // // //                   icon: statusIcon,
// // // // // //                   label: 'Statut: ${statusLabel.toUpperCase()}',
// // // // // //                   color: statusColor,
// // // // // //                 ),
// // // // // //                 if (info != null)
// // // // // //                   _StatusChip(
// // // // // //                     icon: info.assurance ? Icons.shield : Icons.shield_outlined,
// // // // // //                     label: 'Assurance: ${info.assurance ? 'OUI' : 'NON'}',
// // // // // //                     color: info.assurance
// // // // // //                         ? Colors.green.shade600
// // // // // //                         : Colors.orange.shade700,
// // // // // //                   ),
// // // // // //               ],
// // // // // //             ),
// // // // // //             const SizedBox(height: 10),

// // // // // //             // Dates assurance
// // // // // //             if (info != null)
// // // // // //               Row(
// // // // // //                 children: [
// // // // // //                   const Icon(Icons.today, size: 18),
// // // // // //                   const SizedBox(width: 6),
// // // // // //                   Text('Début: ${_fmtDate(info.assuranceStart)}'),
// // // // // //                   const SizedBox(width: 16),
// // // // // //                   const Icon(Icons.event, size: 18),
// // // // // //                   const SizedBox(width: 6),
// // // // // //                   Text('Fin: ${_fmtDate(info.assuranceEnd)}'),
// // // // // //                 ],
// // // // // //               ),

// // // // // //             const SizedBox(height: 12),
// // // // // //             const Divider(height: 20),

// // // // // //             // Méta-infos (heure + agent en dur, à brancher à ton auth)
// // // // // //             Row(
// // // // // //               children: [
// // // // // //                 const Icon(Icons.schedule, size: 18),
// // // // // //                 const SizedBox(width: 6),
// // // // // //                 Text(
// // // // // //                   "${now.day.toString().padLeft(2, '0')}/"
// // // // // //                   "${now.month.toString().padLeft(2, '0')}/"
// // // // // //                   "${now.year}  "
// // // // // //                   "${now.hour.toString().padLeft(2, '0')}:"
// // // // // //                   "${now.minute.toString().padLeft(2, '0')}",
// // // // // //                 ),
// // // // // //                 const SizedBox(width: 12),
// // // // // //                 const Icon(Icons.badge, size: 18),
// // // // // //                 const SizedBox(width: 6),
// // // // // //                 const Text(
// // // // // //                   "Agent: PN-34821",
// // // // // //                 ), // TODO: injecter vrai matricule/agent
// // // // // //               ],
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }

// // // // // //   String _fmtDate(DateTime? d) {
// // // // // //     if (d == null) return '—';
// // // // // //     return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
// // // // // //   }
// // // // // // }

// // // // // // // ====== Modèle de données véhicule ======
// // // // // // enum VehicleStatus { vole, non_assure, recherche, ok }

// // // // // // class VehicleInfo {
// // // // // //   final String plate;
// // // // // //   final VehicleStatus status;
// // // // // //   final bool assurance;
// // // // // //   final DateTime? assuranceStart;
// // // // // //   final DateTime? assuranceEnd;

// // // // // //   VehicleInfo({
// // // // // //     required this.plate,
// // // // // //     required this.status,
// // // // // //     required this.assurance,
// // // // // //     required this.assuranceStart,
// // // // // //     required this.assuranceEnd,
// // // // // //   });
// // // // // // }

// // // // // // // ====== Petit chip coloré ======
// // // // // // class _StatusChip extends StatelessWidget {
// // // // // //   final IconData icon;
// // // // // //   final String label;
// // // // // //   final Color color;
// // // // // //   const _StatusChip({
// // // // // //     required this.icon,
// // // // // //     required this.label,
// // // // // //     required this.color,
// // // // // //   });

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Container(
// // // // // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // // // // //       decoration: BoxDecoration(
// // // // // //         color: color.withOpacity(0.12),
// // // // // //         border: Border.all(color: color.withOpacity(0.5)),
// // // // // //         borderRadius: BorderRadius.circular(999),
// // // // // //       ),
// // // // // //       child: Row(
// // // // // //         mainAxisSize: MainAxisSize.min,
// // // // // //         children: [
// // // // // //           Icon(icon, size: 16, color: color),
// // // // // //           const SizedBox(width: 6),
// // // // // //           Text(
// // // // // //             label,
// // // // // //             style: TextStyle(color: color, fontWeight: FontWeight.w600),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }
// // // // // import 'dart:io';
// // // // // import 'dart:ui';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:image_picker/image_picker.dart';
// // // // // import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// // // // // /// -------------------- THEME POLICE --------------------
// // // // // class PoliceColors {
// // // // //   static const green = Color(0xFF00853F);
// // // // //   static const yellow = Color(0xFFFCD116);
// // // // //   static const red = Color(0xFFE31B23);
// // // // //   static const black = Color(0xFF111111);
// // // // //   static const white = Color(0xFFFFFFFF);

// // // // //   // UI
// // // // //   static const charcoal = Color(0xFF181C20);
// // // // //   static const slate = Color(0xFF21262C);
// // // // //   static const glass = Color(0x14FFFFFF); // 8% white
// // // // //   static const stroke = Color(0x26FFFFFF); // 15% white
// // // // // }

// // // // // class PoliceGradients {
// // // // //   static const header = LinearGradient(
// // // // //     colors: [PoliceColors.green, PoliceColors.yellow, PoliceColors.red],
// // // // //     begin: Alignment.centerLeft,
// // // // //     end: Alignment.centerRight,
// // // // //   );

// // // // //   static const bg = LinearGradient(
// // // // //     colors: [Color(0xFF0E1216), Color(0xFF12161B), Color(0xFF151A20)],
// // // // //     begin: Alignment.topLeft,
// // // // //     end: Alignment.bottomRight,
// // // // //   );

// // // // //   static const callToAction = LinearGradient(
// // // // //     colors: [PoliceColors.green, PoliceColors.yellow],
// // // // //     begin: Alignment.topLeft,
// // // // //     end: Alignment.bottomRight,
// // // // //   );
// // // // // }

// // // // // /// -------------------- ECRAN --------------------
// // // // // class PlateRecognitionScreen extends StatefulWidget {
// // // // //   const PlateRecognitionScreen({super.key});

// // // // //   @override
// // // // //   State<PlateRecognitionScreen> createState() => _PlateRecognitionScreenState();
// // // // // }

// // // // // class _PlateRecognitionScreenState extends State<PlateRecognitionScreen> {
// // // // //   final _picker = ImagePicker();
// // // // //   File? _image;
// // // // //   bool _loading = false;

// // // // //   // OCR brut
// // // // //   String _text = '';

// // // // //   // Sortie principale
// // // // //   String? _plate;
// // // // //   double? _confidence; // heuristique locale 0..1

// // // // //   // Infos véhicule
// // // // //   VehicleInfo? _vehicleInfo;

// // // // //   String? _error;

// // // // //   late final TextRecognizer _recognizer = TextRecognizer(
// // // // //     script: TextRecognitionScript.latin,
// // // // //   );

// // // // //   // ========= Flux principal : prendre/choisir, OCR, extraire plaque, charger infos =========
// // // // //   Future<void> _pickAndRecognize(ImageSource source) async {
// // // // //     setState(() {
// // // // //       _loading = true;
// // // // //       _error = null;
// // // // //       _text = '';
// // // // //       _plate = null;
// // // // //       _confidence = null;
// // // // //       _vehicleInfo = null;
// // // // //     });

// // // // //     try {
// // // // //       final picked = await _picker.pickImage(source: source, imageQuality: 95);
// // // // //       if (picked == null) {
// // // // //         setState(() => _loading = false);
// // // // //         return;
// // // // //       }

// // // // //       final file = File(picked.path);
// // // // //       setState(() => _image = file);

// // // // //       final inputImage = InputImage.fromFile(file);
// // // // //       final result = await _recognizer.processImage(inputImage);

// // // // //       final buffer = StringBuffer();
// // // // //       for (final block in result.blocks) {
// // // // //         for (final line in block.lines) {
// // // // //           buffer.writeln(line.text);
// // // // //         }
// // // // //       }
// // // // //       final ocrText = buffer.toString().trim();

// // // // //       final normalized = _normalizeOcr(ocrText);
// // // // //       final candidates = _extractPlateCandidates(normalized);
// // // // //       final best = _pickBestCandidate(candidates);

// // // // //       String? plate;
// // // // //       double? conf;
// // // // //       if (best != null) {
// // // // //         plate = best.$1;
// // // // //         conf = best.$2;
// // // // //       }

// // // // //       setState(() {
// // // // //         _text = ocrText;
// // // // //         _plate = plate;
// // // // //         _confidence = conf;
// // // // //       });

// // // // //       if (plate != null) {
// // // // //         final info = await _loadVehicleInfo(plate);
// // // // //         setState(() => _vehicleInfo = info);
// // // // //       }
// // // // //     } catch (e) {
// // // // //       setState(() => _error = e.toString());
// // // // //     } finally {
// // // // //       setState(() => _loading = false);
// // // // //     }
// // // // //   }

// // // // //   // ========= MOCK: remplace par tes vrais appels API =========
// // // // //   Future<VehicleInfo> _loadVehicleInfo(String plate) async {
// // // // //     await Future<void>.delayed(const Duration(milliseconds: 300));
// // // // //     if (plate.contains('VOLE')) {
// // // // //       return VehicleInfo(
// // // // //         plate: plate,
// // // // //         status: VehicleStatus.vole,
// // // // //         assurance: false,
// // // // //       );
// // // // //     }
// // // // //     if (plate.contains('NSA') || plate.contains('NONASSURE')) {
// // // // //       return VehicleInfo(
// // // // //         plate: plate,
// // // // //         status: VehicleStatus.non_assure,
// // // // //         assurance: false,
// // // // //       );
// // // // //     }
// // // // //     if (plate.contains('SRCH') || plate.contains('WANTED')) {
// // // // //       return VehicleInfo(
// // // // //         plate: plate,
// // // // //         status: VehicleStatus.recherche,
// // // // //         assurance: true,
// // // // //         assuranceStart: DateTime.now().subtract(const Duration(days: 30)),
// // // // //         assuranceEnd: DateTime.now().add(const Duration(days: 335)),
// // // // //       );
// // // // //     }
// // // // //     final start = DateTime.now().subtract(const Duration(days: 15));
// // // // //     final end = DateTime(start.year + 1, start.month, start.day);
// // // // //     return VehicleInfo(
// // // // //       plate: plate,
// // // // //       status: VehicleStatus.ok,
// // // // //       assurance: true,
// // // // //       assuranceStart: start,
// // // // //       assuranceEnd: end,
// // // // //     );
// // // // //   }

// // // // //   // ========= Utilitaires OCR/Heuristique =========
// // // // //   String _normalizeOcr(String s) {
// // // // //     final up = s.toUpperCase();
// // // // //     return up.replaceAll(RegExp(r'[·•]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
// // // // //   }

// // // // //   final List<RegExp> _platePatterns = [
// // // // //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{3,4}[-\s]?[A-Z]{1,3}\b'),
// // // // //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{2,4}[-\s]?[A-Z]{1,3}\b'),
// // // // //     RegExp(r'\b\d{2,4}[-\s]?[A-Z]{1,3}[-\s]?\d{2,4}\b'),
// // // // //     RegExp(r'\b[A-Z0-9]{6,10}\b'),
// // // // //   ];

// // // // //   List<String> _extractPlateCandidates(String normalized) {
// // // // //     final List<String> res = [];
// // // // //     for (final rgx in _platePatterns) {
// // // // //       for (final m in rgx.allMatches(normalized)) {
// // // // //         var cand = m.group(0)!;
// // // // //         cand = cand.replaceAll(RegExp(r'\s+'), '-');
// // // // //         cand = cand.replaceAll(RegExp(r'-{2,}'), '-');
// // // // //         res.add(cand);
// // // // //       }
// // // // //     }
// // // // //     final seen = <String>{};
// // // // //     final uniq = <String>[];
// // // // //     for (final c in res) {
// // // // //       if (seen.add(c)) uniq.add(c);
// // // // //     }
// // // // //     return uniq;
// // // // //   }

// // // // //   (String, double)? _pickBestCandidate(List<String> candidates) {
// // // // //     if (candidates.isEmpty) return null;

// // // // //     double scoreOf(String c) {
// // // // //       final s = c.replaceAll('-', '');
// // // // //       if (s.length < 5 || s.length > 10) return 0.1;

// // // // //       final letters = RegExp(r'[A-Z]').allMatches(s).length;
// // // // //       final digits = RegExp(r'\d').allMatches(s).length;
// // // // //       double score = 0.5;

// // // // //       if (letters > 0 && digits > 0) score += 0.2;
// // // // //       if (c.contains('-')) score += 0.1;
// // // // //       if (RegExp(r'(.)\1{2,}').hasMatch(s)) score -= 0.2;
// // // // //       if (s.length >= 7 && s.length <= 8) score += 0.1;

// // // // //       return score.clamp(0, 1);
// // // // //     }

// // // // //     String best = candidates.first;
// // // // //     double bestScore = scoreOf(best);
// // // // //     for (final c in candidates.skip(1)) {
// // // // //       final sc = scoreOf(c);
// // // // //       if (sc > bestScore) {
// // // // //         best = c;
// // // // //         bestScore = sc;
// // // // //       }
// // // // //     }
// // // // //     return (best, bestScore);
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _recognizer.close();
// // // // //     super.dispose();
// // // // //   }

// // // // //   // ========= UI =========
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = Theme.of(context);
// // // // //     final now = DateTime.now();
// // // // //     final confPct = _confidence != null
// // // // //         ? (_confidence! * 100).toStringAsFixed(0)
// // // // //         : null;

// // // // //     return Scaffold(
// // // // //       backgroundColor: PoliceColors.charcoal,
// // // // //       body: Stack(
// // // // //         children: [
// // // // //           // BG gradient + léger motif radial
// // // // //           Container(
// // // // //             decoration: const BoxDecoration(gradient: PoliceGradients.bg),
// // // // //           ),
// // // // //           Positioned(
// // // // //             top: -120,
// // // // //             right: -60,
// // // // //             child: Container(
// // // // //               width: 300,
// // // // //               height: 300,
// // // // //               decoration: BoxDecoration(
// // // // //                 shape: BoxShape.circle,
// // // // //                 gradient: RadialGradient(
// // // // //                   colors: [
// // // // //                     PoliceColors.red.withOpacity(0.08),
// // // // //                     Colors.transparent,
// // // // //                   ],
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           Positioned(
// // // // //             bottom: -120,
// // // // //             left: -60,
// // // // //             child: Container(
// // // // //               width: 300,
// // // // //               height: 300,
// // // // //               decoration: BoxDecoration(
// // // // //                 shape: BoxShape.circle,
// // // // //                 gradient: RadialGradient(
// // // // //                   colors: [
// // // // //                     PoliceColors.green.withOpacity(0.08),
// // // // //                     Colors.transparent,
// // // // //                   ],
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //           ),

// // // // //           SafeArea(
// // // // //             child: Column(
// // // // //               children: [
// // // // //                 _HeaderBar(),

// // // // //                 // Contenu
// // // // //                 Expanded(
// // // // //                   child: Padding(
// // // // //                     padding: const EdgeInsets.symmetric(
// // // // //                       horizontal: 16,
// // // // //                       vertical: 10,
// // // // //                     ),
// // // // //                     child: ListView(
// // // // //                       children: [
// // // // //                         // Aperçu image dans une carte "glass"
// // // // //                         _Glass(
// // // // //                           child: AspectRatio(
// // // // //                             aspectRatio: 16 / 10,
// // // // //                             child: ClipRRect(
// // // // //                               borderRadius: BorderRadius.circular(16),
// // // // //                               child: _image != null
// // // // //                                   ? Image.file(_image!, fit: BoxFit.cover)
// // // // //                                   : Container(
// // // // //                                       decoration: BoxDecoration(
// // // // //                                         gradient: LinearGradient(
// // // // //                                           colors: [
// // // // //                                             PoliceColors.slate,
// // // // //                                             PoliceColors.slate.withOpacity(0.7),
// // // // //                                           ],
// // // // //                                           begin: Alignment.topLeft,
// // // // //                                           end: Alignment.bottomRight,
// // // // //                                         ),
// // // // //                                       ),
// // // // //                                       child: Center(
// // // // //                                         child: Column(
// // // // //                                           mainAxisSize: MainAxisSize.min,
// // // // //                                           children: [
// // // // //                                             Icon(
// // // // //                                               Icons.photo_camera_front_rounded,
// // // // //                                               size: 42,
// // // // //                                               color: Colors.white.withOpacity(
// // // // //                                                 .9,
// // // // //                                               ),
// // // // //                                             ),
// // // // //                                             const SizedBox(height: 8),
// // // // //                                             Text(
// // // // //                                               'Prendre une photo ou choisir une image',
// // // // //                                               style: theme.textTheme.bodyMedium
// // // // //                                                   ?.copyWith(
// // // // //                                                     color: Colors.white
// // // // //                                                         .withOpacity(.85),
// // // // //                                                   ),
// // // // //                                               textAlign: TextAlign.center,
// // // // //                                             ),
// // // // //                                           ],
// // // // //                                         ),
// // // // //                                       ),
// // // // //                                     ),
// // // // //                             ),
// // // // //                           ),
// // // // //                         ),

// // // // //                         const SizedBox(height: 12),
// // // // //                         if (_loading) const LinearProgressIndicator(),

// // // // //                         // Erreur
// // // // //                         if (_error != null) ...[
// // // // //                           const SizedBox(height: 10),
// // // // //                           _Glass(
// // // // //                             color: Colors.red.withOpacity(.08),
// // // // //                             border: Colors.red.withOpacity(.25),
// // // // //                             child: Row(
// // // // //                               children: [
// // // // //                                 const Icon(
// // // // //                                   Icons.error_outline,
// // // // //                                   color: Colors.red,
// // // // //                                 ),
// // // // //                                 const SizedBox(width: 10),
// // // // //                                 Expanded(
// // // // //                                   child: Text(
// // // // //                                     'Erreur: $_error',
// // // // //                                     style: theme.textTheme.bodyMedium?.copyWith(
// // // // //                                       color: Colors.red,
// // // // //                                     ),
// // // // //                                   ),
// // // // //                                 ),
// // // // //                               ],
// // // // //                             ),
// // // // //                           ),
// // // // //                         ],

// // // // //                         // Carte infos véhicule
// // // // //                         if (_plate != null || _vehicleInfo != null) ...[
// // // // //                           const SizedBox(height: 12),
// // // // //                           _VehicleInfoCard(
// // // // //                             plate: _plate,
// // // // //                             info: _vehicleInfo,
// // // // //                             confidencePct: confPct,
// // // // //                             now: now,
// // // // //                           ),
// // // // //                         ],

// // // // //                         // (Optionnel) OCR brut – masqué par défaut
// // // // //                         // const SizedBox(height: 12),
// // // // //                         // _Glass(
// // // // //                         //   child: Text(
// // // // //                         //     _text.isEmpty ? '— Résultat OCR —' : _text,
// // // // //                         //     style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
// // // // //                         //   ),
// // // // //                         // ),
// // // // //                         const SizedBox(height: 90), // pour la barre d’actions
// // // // //                       ],
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),

// // // // //                 // Barre d’actions flottante (caméra / galerie)
// // // // //                 _BottomActionBar(
// // // // //                   onCamera: _loading
// // // // //                       ? null
// // // // //                       : () => _pickAndRecognize(ImageSource.camera),
// // // // //                   onGallery: _loading
// // // // //                       ? null
// // // // //                       : () => _pickAndRecognize(ImageSource.gallery),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   String _fmtDate(DateTime? d) {
// // // // //     if (d == null) return '—';
// // // // //     return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
// // // // //   }
// // // // // }

// // // // // /// -------------------- HEADER --------------------
// // // // // class _HeaderBar extends StatelessWidget {
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final t = Theme.of(context);
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
// // // // //       child: Row(
// // // // //         children: [
// // // // //           _Shield(),
// // // // //           const SizedBox(width: 12),
// // // // //           Expanded(
// // // // //             child: Column(
// // // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // // //               children: [
// // // // //                 ShaderMask(
// // // // //                   shaderCallback: (r) => PoliceGradients.header.createShader(r),
// // // // //                   child: Text(
// // // // //                     'SÛRETÉ & ORDRE',
// // // // //                     style: t.textTheme.titleMedium?.copyWith(
// // // // //                       color: Colors.white,
// // // // //                       fontWeight: FontWeight.w800,
// // // // //                       letterSpacing: 1.2,
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 3),
// // // // //                 Text(
// // // // //                   'Scan véhicules • LAPI',
// // // // //                   style: t.textTheme.bodySmall?.copyWith(
// // // // //                     color: Colors.white.withOpacity(.75),
// // // // //                     letterSpacing: .5,
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //           const SizedBox(width: 12),
// // // // //           Container(
// // // // //             height: 32,
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 10),
// // // // //             decoration: BoxDecoration(
// // // // //               borderRadius: BorderRadius.circular(999),
// // // // //               border: Border.all(color: PoliceColors.stroke),
// // // // //               color: PoliceColors.glass,
// // // // //             ),
// // // // //             alignment: Alignment.center,
// // // // //             child: const Text(
// // // // //               'v1.0',
// // // // //               style: TextStyle(
// // // // //                 color: Colors.white70,
// // // // //                 fontWeight: FontWeight.w600,
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _Shield extends StatelessWidget {
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return _Glass(
// // // // //       blur: 6,
// // // // //       borderRadius: 12,
// // // // //       child: Row(
// // // // //         mainAxisSize: MainAxisSize.min,
// // // // //         children: [
// // // // //           const SizedBox(width: 8),
// // // // //           Container(
// // // // //             height: 38,
// // // // //             width: 38,
// // // // //             decoration: BoxDecoration(
// // // // //               borderRadius: BorderRadius.circular(8),
// // // // //               border: Border.all(color: PoliceColors.stroke),
// // // // //               color: Colors.white,
// // // // //             ),
// // // // //             child: ClipRRect(
// // // // //               borderRadius: BorderRadius.circular(8),
// // // // //               child: Image.asset('assets/police_logo.png', fit: BoxFit.contain),
// // // // //             ),
// // // // //           ),
// // // // //           const SizedBox(width: 10),
// // // // //           const SizedBox(
// // // // //             height: 28,
// // // // //             child: VerticalDivider(color: PoliceColors.stroke, thickness: 1),
// // // // //           ),
// // // // //           const SizedBox(width: 10),
// // // // //           ShaderMask(
// // // // //             shaderCallback: (r) => PoliceGradients.header.createShader(r),
// // // // //             child: const Icon(Icons.shield, color: Colors.white, size: 20),
// // // // //           ),
// // // // //           const SizedBox(width: 8),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // /// -------------------- VEHICLE INFO CARD --------------------
// // // // // class _VehicleInfoCard extends StatelessWidget {
// // // // //   final String? plate;
// // // // //   final VehicleInfo? info;
// // // // //   final String? confidencePct;
// // // // //   final DateTime now;

// // // // //   const _VehicleInfoCard({
// // // // //     required this.plate,
// // // // //     required this.info,
// // // // //     required this.confidencePct,
// // // // //     required this.now,
// // // // //   });

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final t = Theme.of(context);

// // // // //     final label = _statusLabel(info?.status);
// // // // //     final statusColor = _statusColor(info?.status);
// // // // //     final statusIcon = _statusIcon(info?.status);

// // // // //     return _Glass(
// // // // //       child: Column(
// // // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // // //         children: [
// // // // //           // En-tête
// // // // //           Row(
// // // // //             children: [
// // // // //               ShaderMask(
// // // // //                 shaderCallback: (r) => PoliceGradients.header.createShader(r),
// // // // //                 child: const Icon(
// // // // //                   Icons.directions_car,
// // // // //                   color: Colors.white,
// // // // //                   size: 24,
// // // // //                 ),
// // // // //               ),
// // // // //               const SizedBox(width: 10),
// // // // //               Expanded(
// // // // //                 child: Text(
// // // // //                   plate ?? '—',
// // // // //                   style: t.textTheme.titleLarge?.copyWith(
// // // // //                     color: Colors.white,
// // // // //                     fontWeight: FontWeight.w800,
// // // // //                     letterSpacing: 1.0,
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //               if (confidencePct != null)
// // // // //                 _Pill(
// // // // //                   icon: Icons.insights,
// // // // //                   label: 'Confiance $confidencePct%',
// // // // //                   color: Colors.white.withOpacity(.85),
// // // // //                 ),
// // // // //             ],
// // // // //           ),

// // // // //           const SizedBox(height: 12),

// // // // //           // Statut + Assurance
// // // // //           Wrap(
// // // // //             spacing: 8,
// // // // //             runSpacing: 8,
// // // // //             children: [
// // // // //               _Pill(
// // // // //                 icon: statusIcon,
// // // // //                 label: 'Statut : ${label.toUpperCase()}',
// // // // //                 color: statusColor,
// // // // //               ),
// // // // //               if (info != null)
// // // // //                 _Pill(
// // // // //                   icon: info!.assurance ? Icons.shield : Icons.shield_outlined,
// // // // //                   label: 'Assurance : ${info!.assurance ? 'OUI' : 'NON'}',
// // // // //                   color: info!.assurance
// // // // //                       ? PoliceColors.green
// // // // //                       : PoliceColors.red,
// // // // //                 ),
// // // // //             ],
// // // // //           ),

// // // // //           const SizedBox(height: 10),
// // // // //           const Divider(height: 20, color: PoliceColors.stroke),

// // // // //           // Dates d’assurance
// // // // //           Row(
// // // // //             children: [
// // // // //               const Icon(Icons.today, size: 18, color: Colors.white70),
// // // // //               const SizedBox(width: 6),
// // // // //               Text(
// // // // //                 'Début : ${_fmtDate(info?.assuranceStart)}',
// // // // //                 style: t.textTheme.bodyMedium?.copyWith(color: Colors.white70),
// // // // //               ),
// // // // //               const SizedBox(width: 16),
// // // // //               const Icon(Icons.event, size: 18, color: Colors.white70),
// // // // //               const SizedBox(width: 6),
// // // // //               Text(
// // // // //                 'Fin : ${_fmtDate(info?.assuranceEnd)}',
// // // // //                 style: t.textTheme.bodyMedium?.copyWith(color: Colors.white70),
// // // // //               ),
// // // // //             ],
// // // // //           ),

// // // // //           const SizedBox(height: 12),

// // // // //           // Méta
// // // // //           Row(
// // // // //             children: [
// // // // //               const Icon(Icons.schedule, size: 18, color: Colors.white54),
// // // // //               const SizedBox(width: 6),
// // // // //               Text(
// // // // //                 '${_dd(now.day)}/${_dd(now.month)}/${now.year}  ${_dd(now.hour)}:${_dd(now.minute)}',
// // // // //                 style: t.textTheme.bodySmall?.copyWith(color: Colors.white54),
// // // // //               ),
// // // // //               const SizedBox(width: 12),
// // // // //               const Icon(Icons.badge, size: 18, color: Colors.white54),
// // // // //               const SizedBox(width: 6),
// // // // //               Text(
// // // // //                 'Agent: PN-34821',
// // // // //                 style: t.textTheme.bodySmall?.copyWith(color: Colors.white54),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   static String _dd(int n) => n.toString().padLeft(2, '0');
// // // // //   static String _fmtDate(DateTime? d) =>
// // // // //       d == null ? '—' : '${_dd(d.day)}/${_dd(d.month)}/${d.year}';

// // // // //   Color _statusColor(VehicleStatus? s) {
// // // // //     switch (s) {
// // // // //       case VehicleStatus.vole:
// // // // //         return PoliceColors.red;
// // // // //       case VehicleStatus.non_assure:
// // // // //         return Colors.orange.shade700;
// // // // //       case VehicleStatus.recherche:
// // // // //         return Colors.deepOrange.shade700;
// // // // //       case VehicleStatus.ok:
// // // // //         return PoliceColors.green;
// // // // //       default:
// // // // //         return Colors.white70;
// // // // //     }
// // // // //   }

// // // // //   IconData _statusIcon(VehicleStatus? s) {
// // // // //     switch (s) {
// // // // //       case VehicleStatus.vole:
// // // // //         return Icons.report;
// // // // //       case VehicleStatus.non_assure:
// // // // //         return Icons.shield;
// // // // //       case VehicleStatus.recherche:
// // // // //         return Icons.search;
// // // // //       case VehicleStatus.ok:
// // // // //         return Icons.verified;
// // // // //       default:
// // // // //         return Icons.help_outline;
// // // // //     }
// // // // //   }

// // // // //   String _statusLabel(VehicleStatus? s) {
// // // // //     switch (s) {
// // // // //       case VehicleStatus.vole:
// // // // //         return 'volé';
// // // // //       case VehicleStatus.non_assure:
// // // // //         return 'non assuré';
// // // // //       case VehicleStatus.recherche:
// // // // //         return 'recherché';
// // // // //       case VehicleStatus.ok:
// // // // //         return 'ok';
// // // // //       default:
// // // // //         return 'inconnu';
// // // // //     }
// // // // //   }
// // // // // }

// // // // // /// -------------------- BOTTOM ACTION BAR --------------------
// // // // // class _BottomActionBar extends StatelessWidget {
// // // // //   final VoidCallback? onCamera;
// // // // //   final VoidCallback? onGallery;

// // // // //   const _BottomActionBar({required this.onCamera, required this.onGallery});

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
// // // // //       child: ClipRRect(
// // // // //         borderRadius: BorderRadius.circular(20),
// // // // //         child: BackdropFilter(
// // // // //           filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
// // // // //           child: Container(
// // // // //             decoration: BoxDecoration(
// // // // //               color: PoliceColors.glass,
// // // // //               border: Border.all(color: PoliceColors.stroke),
// // // // //             ),
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
// // // // //             child: Row(
// // // // //               children: [
// // // // //                 Expanded(
// // // // //                   child: _BigButton(
// // // // //                     onPressed: onCamera,
// // // // //                     icon: Icons.photo_camera_rounded,
// // // // //                     label: 'Caméra',
// // // // //                     gradient: PoliceGradients.callToAction,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(width: 10),
// // // // //                 Expanded(
// // // // //                   child: _BigButton(
// // // // //                     onPressed: onGallery,
// // // // //                     icon: Icons.photo_library_rounded,
// // // // //                     label: 'Galerie',
// // // // //                     gradient: const LinearGradient(
// // // // //                       colors: [PoliceColors.red, PoliceColors.yellow],
// // // // //                       begin: Alignment.topLeft,
// // // // //                       end: Alignment.bottomRight,
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _BigButton extends StatelessWidget {
// // // // //   final VoidCallback? onPressed;
// // // // //   final IconData icon;
// // // // //   final String label;
// // // // //   final Gradient gradient;

// // // // //   const _BigButton({
// // // // //     required this.onPressed,
// // // // //     required this.icon,
// // // // //     required this.label,
// // // // //     required this.gradient,
// // // // //   });

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final enabled = onPressed != null;
// // // // //     return Container(
// // // // //       height: 48,
// // // // //       decoration: BoxDecoration(
// // // // //         gradient: enabled ? gradient : null,
// // // // //         color: enabled ? null : Colors.white10,
// // // // //         borderRadius: BorderRadius.circular(14),
// // // // //         border: Border.all(color: PoliceColors.stroke),
// // // // //       ),
// // // // //       child: InkWell(
// // // // //         borderRadius: BorderRadius.circular(14),
// // // // //         onTap: onPressed,
// // // // //         child: Center(
// // // // //           child: Row(
// // // // //             mainAxisSize: MainAxisSize.min,
// // // // //             children: [
// // // // //               Icon(icon, color: Colors.white, size: 20),
// // // // //               const SizedBox(width: 8),
// // // // //               Text(
// // // // //                 label,
// // // // //                 style: const TextStyle(
// // // // //                   color: Colors.white,
// // // // //                   fontWeight: FontWeight.w700,
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // /// -------------------- GLASS WRAPPER --------------------
// // // // // class _Glass extends StatelessWidget {
// // // // //   final Widget child;
// // // // //   final double blur;
// // // // //   final double borderRadius;
// // // // //   final Color? color;
// // // // //   final Color? border;

// // // // //   const _Glass({
// // // // //     super.key,
// // // // //     required this.child,
// // // // //     this.blur = 14,
// // // // //     this.borderRadius = 16,
// // // // //     this.color,
// // // // //     this.border,
// // // // //   });

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return ClipRRect(
// // // // //       borderRadius: BorderRadius.circular(borderRadius),
// // // // //       child: BackdropFilter(
// // // // //         filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
// // // // //         child: Container(
// // // // //           decoration: BoxDecoration(
// // // // //             color: color ?? PoliceColors.glass,
// // // // //             border: Border.all(color: border ?? PoliceColors.stroke),
// // // // //             borderRadius: BorderRadius.circular(borderRadius),
// // // // //           ),
// // // // //           padding: const EdgeInsets.all(14),
// // // // //           child: child,
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // /// -------------------- MODELES --------------------
// // // // // enum VehicleStatus { vole, non_assure, recherche, ok }

// // // // // class VehicleInfo {
// // // // //   final String plate;
// // // // //   final VehicleStatus status;
// // // // //   final bool assurance;
// // // // //   final DateTime? assuranceStart;
// // // // //   final DateTime? assuranceEnd;

// // // // //   VehicleInfo({
// // // // //     required this.plate,
// // // // //     required this.status,
// // // // //     required this.assurance,
// // // // //     this.assuranceStart,
// // // // //     this.assuranceEnd,
// // // // //   });
// // // // // }

// // // // // /// -------------------- PILL (badge arrondi) --------------------
// // // // // class _Pill extends StatelessWidget {
// // // // //   final IconData icon;
// // // // //   final String label;
// // // // //   final Color color;

// // // // //   const _Pill({
// // // // //     super.key,
// // // // //     required this.icon,
// // // // //     required this.label,
// // // // //     required this.color,
// // // // //   });

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Container(
// // // // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // // // //       decoration: BoxDecoration(
// // // // //         color: color.withOpacity(0.12),
// // // // //         border: Border.all(color: color.withOpacity(0.45)),
// // // // //         borderRadius: BorderRadius.circular(999),
// // // // //       ),
// // // // //       child: Row(
// // // // //         mainAxisSize: MainAxisSize.min,
// // // // //         children: [
// // // // //           Icon(icon, size: 16, color: color),
// // // // //           const SizedBox(width: 6),
// // // // //           Text(
// // // // //             label,
// // // // //             style: TextStyle(
// // // // //               color: color,
// // // // //               fontWeight: FontWeight.w700,
// // // // //               letterSpacing: .2,
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'dart:io';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:image_picker/image_picker.dart';
// // // // import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// // // // import 'package:niit/ui/screens/settings.dart';
// // // // import 'package:niit/ui/widgets/app_bar.dart'; // si tu l’utilises déjà
// // // // // import 'package:niit/.../police_brand.dart'; // si PoliceBrand est dans un fichier séparé

// // // // class PlateRecognitionScreen extends StatefulWidget {
// // // //   const PlateRecognitionScreen({super.key});
// // // //   @override
// // // //   State<PlateRecognitionScreen> createState() => _PlateRecognitionScreenState();
// // // // }

// // // // class _PlateRecognitionScreenState extends State<PlateRecognitionScreen> {
// // // //   final _picker = ImagePicker();
// // // //   File? _image;
// // // //   bool _loading = false;

// // // //   // OCR brut
// // // //   String _text = '';

// // // //   // Sortie principale
// // // //   String? _plate;
// // // //   double? _confidence; // heuristique locale 0..1

// // // //   // Infos véhicule (affichage)
// // // //   VehicleInfo? _vehicleInfo;

// // // //   String? _error;

// // // //   late final TextRecognizer _recognizer = TextRecognizer(
// // // //     script: TextRecognitionScript.latin,
// // // //   );

// // // //   // ========= Flux principal : prendre/choisir, OCR, extraire plaque, charger infos =========
// // // //   Future<void> _pickAndRecognize(ImageSource source) async {
// // // //     setState(() {
// // // //       _loading = true;
// // // //       _error = null;
// // // //       _text = '';
// // // //       _plate = null;
// // // //       _confidence = null;
// // // //       _vehicleInfo = null;
// // // //     });

// // // //     try {
// // // //       final picked = await _picker.pickImage(source: source, imageQuality: 95);
// // // //       if (picked == null) {
// // // //         setState(() => _loading = false);
// // // //         return;
// // // //       }

// // // //       final file = File(picked.path);
// // // //       setState(() => _image = file);

// // // //       final inputImage = InputImage.fromFile(file);
// // // //       final result = await _recognizer.processImage(inputImage);

// // // //       final buffer = StringBuffer();
// // // //       for (final block in result.blocks) {
// // // //         for (final line in block.lines) {
// // // //           buffer.writeln(line.text);
// // // //         }
// // // //       }
// // // //       final ocrText = buffer.toString().trim();

// // // //       final normalized = _normalizeOcr(ocrText);
// // // //       final candidates = _extractPlateCandidates(normalized);
// // // //       final best = _pickBestCandidate(candidates);

// // // //       String? plate;
// // // //       double? conf;
// // // //       if (best != null) {
// // // //         plate = best.$1;
// // // //         conf = best.$2;
// // // //       }

// // // //       setState(() {
// // // //         _text = ocrText;
// // // //         _plate = plate;
// // // //         _confidence = conf;
// // // //       });

// // // //       if (plate != null) {
// // // //         final info = await _loadVehicleInfo(plate);
// // // //         setState(() => _vehicleInfo = info);
// // // //       }
// // // //     } catch (e) {
// // // //       setState(() => _error = e.toString());
// // // //     } finally {
// // // //       setState(() => _loading = false);
// // // //     }
// // // //   }

// // // //   // ========= MOCK: remplace par tes vrais appels API =========
// // // //   Future<VehicleInfo> _loadVehicleInfo(String plate) async {
// // // //     await Future<void>.delayed(const Duration(milliseconds: 300));
// // // //     if (plate.contains('VOLE')) {
// // // //       return VehicleInfo(
// // // //         plate: plate,
// // // //         status: VehicleStatus.vole,
// // // //         assurance: false,
// // // //       );
// // // //     }
// // // //     if (plate.contains('NSA') || plate.contains('NONASSURE')) {
// // // //       return VehicleInfo(
// // // //         plate: plate,
// // // //         status: VehicleStatus.non_assure,
// // // //         assurance: false,
// // // //       );
// // // //     }
// // // //     if (plate.contains('SRCH') || plate.contains('WANTED')) {
// // // //       return VehicleInfo(
// // // //         plate: plate,
// // // //         status: VehicleStatus.recherche,
// // // //         assurance: true,
// // // //         assuranceStart: DateTime.now().subtract(const Duration(days: 30)),
// // // //         assuranceEnd: DateTime.now().add(const Duration(days: 335)),
// // // //       );
// // // //     }
// // // //     final start = DateTime.now().subtract(const Duration(days: 15));
// // // //     final end = DateTime(start.year + 1, start.month, start.day);
// // // //     return VehicleInfo(
// // // //       plate: plate,
// // // //       status: VehicleStatus.ok,
// // // //       assurance: true,
// // // //       assuranceStart: start,
// // // //       assuranceEnd: end,
// // // //     );
// // // //   }

// // // //   // ========= Utilitaires OCR/Heuristique =========
// // // //   String _normalizeOcr(String s) {
// // // //     final up = s.toUpperCase();
// // // //     return up.replaceAll(RegExp(r'[·•]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
// // // //   }

// // // //   final List<RegExp> _platePatterns = [
// // // //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{3,4}[-\s]?[A-Z]{1,3}\b'),
// // // //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{2,4}[-\s]?[A-Z]{1,3}\b'),
// // // //     RegExp(r'\b\d{2,4}[-\s]?[A-Z]{1,3}[-\s]?\d{2,4}\b'),
// // // //     RegExp(r'\b[A-Z0-9]{6,10}\b'),
// // // //   ];

// // // //   List<String> _extractPlateCandidates(String normalized) {
// // // //     final List<String> res = [];
// // // //     for (final rgx in _platePatterns) {
// // // //       for (final m in rgx.allMatches(normalized)) {
// // // //         var cand = m.group(0)!;
// // // //         cand = cand.replaceAll(RegExp(r'\s+'), '-');
// // // //         cand = cand.replaceAll(RegExp(r'-{2,}'), '-');
// // // //         res.add(cand);
// // // //       }
// // // //     }
// // // //     final seen = <String>{};
// // // //     final uniq = <String>[];
// // // //     for (final c in res) {
// // // //       if (seen.add(c)) uniq.add(c);
// // // //     }
// // // //     return uniq;
// // // //   }

// // // //   (String, double)? _pickBestCandidate(List<String> candidates) {
// // // //     if (candidates.isEmpty) return null;

// // // //     double scoreOf(String c) {
// // // //       final s = c.replaceAll('-', '');
// // // //       if (s.length < 5 || s.length > 10) return 0.1;

// // // //       final letters = RegExp(r'[A-Z]').allMatches(s).length;
// // // //       final digits = RegExp(r'\d').allMatches(s).length;
// // // //       double score = 0.5;

// // // //       if (letters > 0 && digits > 0) score += 0.2;
// // // //       if (c.contains('-')) score += 0.1;
// // // //       if (RegExp(r'(.)\1{2,}').hasMatch(s)) score -= 0.2;
// // // //       if (s.length >= 7 && s.length <= 8) score += 0.1;

// // // //       return score.clamp(0, 1);
// // // //     }

// // // //     String best = candidates.first;
// // // //     double bestScore = scoreOf(best);
// // // //     for (final c in candidates.skip(1)) {
// // // //       final sc = scoreOf(c);
// // // //       if (sc > bestScore) {
// // // //         best = c;
// // // //         bestScore = sc;
// // // //       }
// // // //     }
// // // //     return (best, bestScore);
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _recognizer.close();
// // // //     super.dispose();
// // // //   }

// // // //   // ========= UI =========
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final confPct = _confidence != null
// // // //         ? (_confidence! * 100).toStringAsFixed(0)
// // // //         : null;
// // // //     final divider = Divider(
// // // //       height: 1,
// // // //       thickness: 1,
// // // //       color: Colors.grey.shade200,
// // // //     );

// // // //     return Scaffold(
// // // //       backgroundColor: PoliceBrand.light,
// // // //       appBar: CustomAppBar(),
// // // //       body: CustomScrollView(
// // // //         slivers: [
// // // //           // ====== HEADER (même style que Settings) ======
// // // //           SliverToBoxAdapter(
// // // //             child: Container(
// // // //               margin: const EdgeInsets.all(12),
// // // //               padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
// // // //               decoration: BoxDecoration(
// // // //                 gradient: PoliceBrand.headerGradient,
// // // //                 borderRadius: PoliceBrand.radiusLg,
// // // //                 image: const DecorationImage(
// // // //                   image: AssetImage('assets/img/police_logo.png'),
// // // //                   alignment: Alignment(1.2, -1.2),
// // // //                   opacity: 0.07,
// // // //                   fit: BoxFit.contain,
// // // //                 ),
// // // //                 boxShadow: const [
// // // //                   BoxShadow(
// // // //                     color: Colors.black12,
// // // //                     blurRadius: 12,
// // // //                     offset: Offset(0, 6),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               child: Row(
// // // //                 children: [
// // // //                   Container(
// // // //                     width: 62,
// // // //                     height: 62,
// // // //                     padding: const EdgeInsets.all(8),
// // // //                     decoration: BoxDecoration(
// // // //                       color: Colors.white,
// // // //                       borderRadius: BorderRadius.circular(14),
// // // //                       border: Border.all(color: Colors.white, width: 2),
// // // //                     ),
// // // //                     child: Image.asset('assets/img/police_logo.png'),
// // // //                   ),
// // // //                   const SizedBox(width: 14),
// // // //                   Expanded(
// // // //                     child: Column(
// // // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // // //                       children: [
// // // //                         Text(
// // // //                           "Scan de plaques",
// // // //                           style: Theme.of(context).textTheme.titleLarge
// // // //                               ?.copyWith(
// // // //                                 color: Colors.white,
// // // //                                 fontWeight: FontWeight.w800,
// // // //                               ),
// // // //                         ),
// // // //                         const SizedBox(height: 4),
// // // //                         Text(
// // // //                           _plate == null
// // // //                               ? "Prêt pour un contrôle"
// // // //                               : "Dernier résultat : $_plate",
// // // //                           style: Theme.of(context).textTheme.bodyMedium
// // // //                               ?.copyWith(color: Colors.white70, height: 1.3),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                   const SizedBox(width: 6),
// // // //                   const _BadgeFlag(),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ),

// // // //           // ====== CONTENU ======
// // // //           SliverToBoxAdapter(
// // // //             child: Padding(
// // // //               padding: const EdgeInsets.symmetric(horizontal: 12),
// // // //               child: Column(
// // // //                 children: [
// // // //                   // --- Aperçu image
// // // //                   _Section(
// // // //                     title: "Aperçu",
// // // //                     accent: PoliceBrand.primary,
// // // //                     children: [
// // // //                       AspectRatio(
// // // //                         aspectRatio: 16 / 10,
// // // //                         child: ClipRRect(
// // // //                           borderRadius: PoliceBrand.radiusLg,
// // // //                           child: _image != null
// // // //                               ? Image.file(_image!, fit: BoxFit.cover)
// // // //                               : Container(
// // // //                                   color: Colors.grey.shade50,
// // // //                                   child: Center(
// // // //                                     child: Column(
// // // //                                       mainAxisSize: MainAxisSize.min,
// // // //                                       children: [
// // // //                                         Icon(
// // // //                                           Icons.photo_camera_front_outlined,
// // // //                                           size: 40,
// // // //                                           color: Colors.grey.shade600,
// // // //                                         ),
// // // //                                         const SizedBox(height: 8),
// // // //                                         Text(
// // // //                                           'Prendre une photo ou choisir une image',
// // // //                                           style: TextStyle(
// // // //                                             color: Colors.grey.shade700,
// // // //                                           ),
// // // //                                         ),
// // // //                                       ],
// // // //                                     ),
// // // //                                   ),
// // // //                                 ),
// // // //                         ),
// // // //                       ),
// // // //                       if (_loading) const LinearProgressIndicator(),
// // // //                       if (_error != null)
// // // //                         Padding(
// // // //                           padding: const EdgeInsets.only(top: 10),
// // // //                           child: Row(
// // // //                             children: [
// // // //                               const Icon(
// // // //                                 Icons.error_outline,
// // // //                                 color: Colors.red,
// // // //                               ),
// // // //                               const SizedBox(width: 8),
// // // //                               Expanded(
// // // //                                 child: Text(
// // // //                                   'Erreur: $_error',
// // // //                                   style: const TextStyle(color: Colors.red),
// // // //                                 ),
// // // //                               ),
// // // //                             ],
// // // //                           ),
// // // //                         ),
// // // //                       const SizedBox(height: 8),
// // // //                       Row(
// // // //                         children: [
// // // //                           Expanded(
// // // //                             child: FilledButton.icon(
// // // //                               style: FilledButton.styleFrom(
// // // //                                 backgroundColor: PoliceBrand.green,
// // // //                                 shape: RoundedRectangleBorder(
// // // //                                   borderRadius: PoliceBrand.radiusSm,
// // // //                                 ),
// // // //                               ),
// // // //                               onPressed: _loading
// // // //                                   ? null
// // // //                                   : () => _pickAndRecognize(ImageSource.camera),
// // // //                               icon: const Icon(Icons.photo_camera),
// // // //                               label: const Text('Caméra'),
// // // //                             ),
// // // //                           ),
// // // //                           const SizedBox(width: 10),
// // // //                           Expanded(
// // // //                             child: OutlinedButton.icon(
// // // //                               style: OutlinedButton.styleFrom(
// // // //                                 foregroundColor: PoliceBrand.primary,
// // // //                                 side: const BorderSide(
// // // //                                   color: PoliceBrand.primary,
// // // //                                   width: 1.2,
// // // //                                 ),
// // // //                                 shape: RoundedRectangleBorder(
// // // //                                   borderRadius: PoliceBrand.radiusSm,
// // // //                                 ),
// // // //                               ),
// // // //                               onPressed: _loading
// // // //                                   ? null
// // // //                                   : () =>
// // // //                                         _pickAndRecognize(ImageSource.gallery),
// // // //                               icon: const Icon(Icons.photo_library),
// // // //                               label: const Text('Galerie'),
// // // //                             ),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                     ],
// // // //                   ),

// // // //                   // --- Résultat & Infos véhicule
// // // //                   _Section(
// // // //                     title: "Résultat du scan",
// // // //                     accent: PoliceBrand.green,
// // // //                     stripeColors: const [
// // // //                       PoliceBrand.green,
// // // //                       PoliceBrand.yellow,
// // // //                       PoliceBrand.red,
// // // //                     ],
// // // //                     children: [
// // // //                       ListTile(
// // // //                         leading: const Icon(Icons.directions_car),
// // // //                         title: Text(_plate ?? '—'),
// // // //                         subtitle: Text(
// // // //                           confPct == null
// // // //                               ? 'Confiance —'
// // // //                               : 'Confiance $confPct%',
// // // //                           style: TextStyle(color: Colors.grey.shade600),
// // // //                         ),
// // // //                       ),

// // // //                       divider,
// // // //                       Padding(
// // // //                         padding: const EdgeInsets.symmetric(
// // // //                           horizontal: 12,
// // // //                           vertical: 8,
// // // //                         ),
// // // //                         child: Wrap(
// // // //                           spacing: 10,
// // // //                           runSpacing: 10,
// // // //                           children: [
// // // //                             _pillStatus(_vehicleInfo?.status),
// // // //                             if (_vehicleInfo != null)
// // // //                               _Pill(
// // // //                                 icon: _vehicleInfo!.assurance
// // // //                                     ? Icons.shield
// // // //                                     : Icons.shield_outlined,
// // // //                                 label:
// // // //                                     'Assurance : ${_vehicleInfo!.assurance ? 'OUI' : 'NON'}',
// // // //                                 color: _vehicleInfo!.assurance
// // // //                                     ? PoliceBrand.green
// // // //                                     : PoliceBrand.red,
// // // //                               ),
// // // //                           ],
// // // //                         ),
// // // //                       ),
// // // //                       if (_vehicleInfo != null) ...[
// // // //                         const SizedBox(height: 6),
// // // //                         Padding(
// // // //                           padding: const EdgeInsets.symmetric(
// // // //                             horizontal: 16,
// // // //                             vertical: 8,
// // // //                           ),
// // // //                           child: Row(
// // // //                             children: [
// // // //                               const Icon(Icons.today, size: 18),
// // // //                               const SizedBox(width: 6),
// // // //                               Text(
// // // //                                 'Début: ${_fmtDate(_vehicleInfo!.assuranceStart)}',
// // // //                               ),
// // // //                               const SizedBox(width: 16),
// // // //                               const Icon(Icons.event, size: 18),
// // // //                               const SizedBox(width: 6),
// // // //                               Text(
// // // //                                 'Fin: ${_fmtDate(_vehicleInfo!.assuranceEnd)}',
// // // //                               ),
// // // //                             ],
// // // //                           ),
// // // //                         ),
// // // //                       ],
// // // //                       const SizedBox(height: 8),
// // // //                     ],
// // // //                   ),

// // // //                   // (Optionnel) OCR brut — désactivé
// // // //                   // _Section(
// // // //                   //   title: "Texte OCR (debug)",
// // // //                   //   accent: PoliceBrand.primary,
// // // //                   //   children: [
// // // //                   //     Padding(
// // // //                   //       padding: const EdgeInsets.all(12.0),
// // // //                   //       child: SelectableText(
// // // //                   //         _text.isEmpty ? '— Résultat OCR —' : _text,
// // // //                   //         style: const TextStyle(fontSize: 14),
// // // //                   //       ),
// // // //                   //     ),
// // // //                   //   ],
// // // //                   // ),
// // // //                   const SizedBox(height: 16),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   String _fmtDate(DateTime? d) => (d == null)
// // // //       ? '—'
// // // //       : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// // // //   // ---- Pills helpers
// // // //   Widget _pillStatus(VehicleStatus? s) {
// // // //     switch (s) {
// // // //       case VehicleStatus.vole:
// // // //         return const _Pill(
// // // //           icon: Icons.report,
// // // //           label: 'Statut : VOLÉ',
// // // //           color: PoliceBrand.red,
// // // //         );
// // // //       case VehicleStatus.non_assure:
// // // //         return const _Pill(
// // // //           icon: Icons.shield,
// // // //           label: 'Statut : NON ASSURÉ',
// // // //           color: Color(0xFFFB8C00),
// // // //         );
// // // //       case VehicleStatus.recherche:
// // // //         return const _Pill(
// // // //           icon: Icons.search,
// // // //           label: 'Statut : RECHERCHÉ',
// // // //           color: Color(0xFFEF6C00),
// // // //         );
// // // //       case VehicleStatus.ok:
// // // //         return const _Pill(
// // // //           icon: Icons.verified,
// // // //           label: 'Statut : OK',
// // // //           color: PoliceBrand.green,
// // // //         );
// // // //       default:
// // // //         return _Pill(
// // // //           icon: Icons.help_outline,
// // // //           label: 'Statut : INCONNU',
// // // //           color: Colors.grey.shade700,
// // // //         );
// // // //     }
// // // //   }
// // // // }

// // // // // ====== Modèle de données véhicule ======
// // // // enum VehicleStatus { vole, non_assure, recherche, ok }

// // // // class VehicleInfo {
// // // //   final String plate;
// // // //   final VehicleStatus status;
// // // //   final bool assurance;
// // // //   final DateTime? assuranceStart;
// // // //   final DateTime? assuranceEnd;
// // // //   VehicleInfo({
// // // //     required this.plate,
// // // //     required this.status,
// // // //     required this.assurance,
// // // //     this.assuranceStart,
// // // //     this.assuranceEnd,
// // // //   });
// // // // }

// // // // /// ---------- UI helpers (recyclés de Settings) ----------
// // // // class _BadgeFlag extends StatelessWidget {
// // // //   const _BadgeFlag();
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return ClipRRect(
// // // //       borderRadius: PoliceBrand.radiusSm,
// // // //       child: Row(
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: const [
// // // //           _FlagStripe(color: PoliceBrand.green),
// // // //           _FlagStripe(color: PoliceBrand.yellow),
// // // //           _FlagStripe(color: PoliceBrand.red),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _FlagStripe extends StatelessWidget {
// // // //   final Color color;
// // // //   const _FlagStripe({required this.color});
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Container(width: 8, height: 40, color: color);
// // // //   }
// // // // }

// // // // class _Section extends StatelessWidget {
// // // //   final String title;
// // // //   final List<Widget> children;
// // // //   final Color accent;
// // // //   final List<Color>? stripeColors;
// // // //   const _Section({
// // // //     required this.title,
// // // //     required this.children,
// // // //     required this.accent,
// // // //     this.stripeColors,
// // // //   });

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final titleRow = Row(
// // // //       children: [
// // // //         Container(
// // // //           width: 4,
// // // //           height: 18,
// // // //           decoration: BoxDecoration(
// // // //             color: accent,
// // // //             borderRadius: BorderRadius.circular(2),
// // // //           ),
// // // //         ),
// // // //         const SizedBox(width: 8),
// // // //         Text(
// // // //           title,
// // // //           style: Theme.of(context).textTheme.titleMedium?.copyWith(
// // // //             fontWeight: FontWeight.w800,
// // // //             color: PoliceBrand.dark,
// // // //           ),
// // // //         ),
// // // //         const Spacer(),
// // // //         if (stripeColors != null)
// // // //           Row(
// // // //             children: stripeColors!
// // // //                 .map(
// // // //                   (c) => Container(
// // // //                     width: 10,
// // // //                     height: 10,
// // // //                     margin: const EdgeInsets.only(left: 4),
// // // //                     decoration: BoxDecoration(
// // // //                       color: c,
// // // //                       borderRadius: BorderRadius.circular(2),
// // // //                     ),
// // // //                   ),
// // // //                 )
// // // //                 .toList(),
// // // //           ),
// // // //       ],
// // // //     );

// // // //     final card = Card(
// // // //       color: PoliceBrand.surface,
// // // //       clipBehavior: Clip.antiAlias,
// // // //       elevation: 0,
// // // //       shape: RoundedRectangleBorder(borderRadius: PoliceBrand.radiusLg),
// // // //       child: Column(children: children),
// // // //     );

// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(bottom: 12),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           Padding(
// // // //             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
// // // //             child: titleRow,
// // // //           ),
// // // //           card,
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _Pill extends StatelessWidget {
// // // //   final IconData icon;
// // // //   final String label;
// // // //   final Color color;
// // // //   const _Pill({required this.icon, required this.label, required this.color});

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Container(
// // // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // // //       decoration: BoxDecoration(
// // // //         color: color.withOpacity(0.08),
// // // //         border: Border.all(color: color.withOpacity(0.35)),
// // // //         borderRadius: BorderRadius.circular(999),
// // // //       ),
// // // //       child: Row(
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: [
// // // //           Icon(icon, size: 16, color: color),
// // // //           const SizedBox(width: 6),
// // // //           Text(
// // // //             label,
// // // //             style: TextStyle(color: color, fontWeight: FontWeight.w700),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'dart:io';
// // // import 'package:flutter/material.dart';
// // // import 'package:image_picker/image_picker.dart';
// // // import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// // // import 'package:niit/ui/screens/settings.dart';
// // // import 'package:niit/ui/widgets/app_bar.dart'; // garde-le si tu l'utilises déjà

// // // class PlateRecognitionScreen extends StatefulWidget {
// // //   const PlateRecognitionScreen({super.key});
// // //   @override
// // //   State<PlateRecognitionScreen> createState() => _PlateRecognitionScreenState();
// // // }

// // // class _PlateRecognitionScreenState extends State<PlateRecognitionScreen> {
// // //   final _picker = ImagePicker();
// // //   File? _image;
// // //   bool _loading = false;

// // //   // OCR brut
// // //   String _text = '';

// // //   // Sortie principale
// // //   String? _plate;
// // //   double? _confidence; // heuristique locale 0..1

// // //   // Infos véhicule
// // //   VehicleInfo? _vehicleInfo;

// // //   String? _error;

// // //   late final TextRecognizer _recognizer = TextRecognizer(
// // //     script: TextRecognitionScript.latin,
// // //   );

// // //   // ========= Flux principal : prendre/choisir, OCR, extraire plaque, charger infos =========
// // //   Future<void> _pickAndRecognize(ImageSource source) async {
// // //     setState(() {
// // //       _loading = true;
// // //       _error = null;
// // //       _text = '';
// // //       _plate = null;
// // //       _confidence = null;
// // //       _vehicleInfo = null;
// // //     });

// // //     try {
// // //       final picked = await _picker.pickImage(source: source, imageQuality: 95);
// // //       if (picked == null) {
// // //         setState(() => _loading = false);
// // //         return;
// // //       }

// // //       final file = File(picked.path);
// // //       setState(() => _image = file);

// // //       final inputImage = InputImage.fromFile(file);
// // //       final result = await _recognizer.processImage(inputImage);

// // //       final buffer = StringBuffer();
// // //       for (final block in result.blocks) {
// // //         for (final line in block.lines) {
// // //           buffer.writeln(line.text);
// // //         }
// // //       }
// // //       final ocrText = buffer.toString().trim();

// // //       final normalized = _normalizeOcr(ocrText);
// // //       final candidates = _extractPlateCandidates(normalized);
// // //       final best = _pickBestCandidate(candidates);

// // //       String? plate;
// // //       double? conf;
// // //       if (best != null) {
// // //         plate = best.$1;
// // //         conf = best.$2;
// // //       }

// // //       setState(() {
// // //         _text = ocrText;
// // //         _plate = plate;
// // //         _confidence = conf;
// // //       });

// // //       if (plate != null) {
// // //         final info = await _loadVehicleInfo(plate);
// // //         setState(() => _vehicleInfo = info);
// // //       }
// // //     } catch (e) {
// // //       setState(() => _error = e.toString());
// // //     } finally {
// // //       setState(() => _loading = false);
// // //     }
// // //   }

// // //   // ========= MOCK: remplace par tes vrais appels API =========
// // //   Future<VehicleInfo> _loadVehicleInfo(String plate) async {
// // //     await Future<void>.delayed(const Duration(milliseconds: 300));
// // //     if (plate.contains('VOLE')) {
// // //       return VehicleInfo(
// // //         plate: plate,
// // //         status: VehicleStatus.vole,
// // //         assurance: false,
// // //       );
// // //     }
// // //     if (plate.contains('NSA') || plate.contains('NONASSURE')) {
// // //       return VehicleInfo(
// // //         plate: plate,
// // //         status: VehicleStatus.non_assure,
// // //         assurance: false,
// // //       );
// // //     }
// // //     if (plate.contains('SRCH') || plate.contains('WANTED')) {
// // //       return VehicleInfo(
// // //         plate: plate,
// // //         status: VehicleStatus.recherche,
// // //         assurance: true,
// // //         assuranceStart: DateTime.now().subtract(const Duration(days: 30)),
// // //         assuranceEnd: DateTime.now().add(const Duration(days: 335)),
// // //       );
// // //     }
// // //     final start = DateTime.now().subtract(const Duration(days: 15));
// // //     final end = DateTime(start.year + 1, start.month, start.day);
// // //     return VehicleInfo(
// // //       plate: plate,
// // //       status: VehicleStatus.ok,
// // //       assurance: true,
// // //       assuranceStart: start,
// // //       assuranceEnd: end,
// // //     );
// // //   }

// // //   // ========= Utilitaires OCR/Heuristique =========
// // //   String _normalizeOcr(String s) {
// // //     final up = s.toUpperCase();
// // //     return up.replaceAll(RegExp(r'[·•]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
// // //   }

// // //   final List<RegExp> _platePatterns = [
// // //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{3,4}[-\s]?[A-Z]{1,3}\b'),
// // //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{2,4}[-\s]?[A-Z]{1,3}\b'),
// // //     RegExp(r'\b\d{2,4}[-\s]?[A-Z]{1,3}[-\s]?\d{2,4}\b'),
// // //     RegExp(r'\b[A-Z0-9]{6,10}\b'),
// // //   ];

// // //   List<String> _extractPlateCandidates(String normalized) {
// // //     final List<String> res = [];
// // //     for (final rgx in _platePatterns) {
// // //       for (final m in rgx.allMatches(normalized)) {
// // //         var cand = m.group(0)!;
// // //         cand = cand.replaceAll(RegExp(r'\s+'), '-');
// // //         cand = cand.replaceAll(RegExp(r'-{2,}'), '-');
// // //         res.add(cand);
// // //       }
// // //     }
// // //     final seen = <String>{};
// // //     final uniq = <String>[];
// // //     for (final c in res) {
// // //       if (seen.add(c)) uniq.add(c);
// // //     }
// // //     return uniq;
// // //   }

// // //   (String, double)? _pickBestCandidate(List<String> candidates) {
// // //     if (candidates.isEmpty) return null;

// // //     double scoreOf(String c) {
// // //       final s = c.replaceAll('-', '');
// // //       if (s.length < 5 || s.length > 10) return 0.1;

// // //       final letters = RegExp(r'[A-Z]').allMatches(s).length;
// // //       final digits = RegExp(r'\d').allMatches(s).length;
// // //       double score = 0.5;

// // //       if (letters > 0 && digits > 0) score += 0.2;
// // //       if (c.contains('-')) score += 0.1;
// // //       if (RegExp(r'(.)\1{2,}').hasMatch(s)) score -= 0.2;
// // //       if (s.length >= 7 && s.length <= 8) score += 0.1;

// // //       return score.clamp(0, 1);
// // //     }

// // //     String best = candidates.first;
// // //     double bestScore = scoreOf(best);
// // //     for (final c in candidates.skip(1)) {
// // //       final sc = scoreOf(c);
// // //       if (sc > bestScore) {
// // //         best = c;
// // //         bestScore = sc;
// // //       }
// // //     }
// // //     return (best, bestScore);
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _recognizer.close();
// // //     super.dispose();
// // //   }

// // //   // ========= Helpers statut (couleur/icone/libellé) =========
// // //   Color _statusColor(VehicleStatus? s) {
// // //     switch (s) {
// // //       case VehicleStatus.vole:
// // //         return PoliceBrand.red; // CAMBRIOLÉ
// // //       case VehicleStatus.recherche:
// // //         return const Color(0xFFEF6C00); // RECHERCHÉ
// // //       case VehicleStatus.ok:
// // //         return PoliceBrand.green; // OK
// // //       case VehicleStatus.non_assure:
// // //         return const Color(0xFFFB8C00); // NON ASSURÉ (optionnel)
// // //       default:
// // //         return Colors.grey.shade700;
// // //     }
// // //   }

// // //   IconData _statusIcon(VehicleStatus? s) {
// // //     switch (s) {
// // //       case VehicleStatus.vole:
// // //         return Icons.report;
// // //       case VehicleStatus.recherche:
// // //         return Icons.search;
// // //       case VehicleStatus.ok:
// // //         return Icons.verified;
// // //       case VehicleStatus.non_assure:
// // //         return Icons.shield;
// // //       default:
// // //         return Icons.help_outline;
// // //     }
// // //   }

// // //   // Libellé demandé : "cambriolé, ok, recherché"
// // //   String _statusLabelCambrioleFirst(VehicleStatus? s) {
// // //     switch (s) {
// // //       case VehicleStatus.vole:
// // //         return 'Cambriolé';
// // //       case VehicleStatus.ok:
// // //         return 'OK';
// // //       case VehicleStatus.recherche:
// // //         return 'Recherché';
// // //       case VehicleStatus.non_assure:
// // //         return 'Non assuré'; // si utile ailleurs
// // //       default:
// // //         return 'Inconnu';
// // //     }
// // //   }

// // //   // ========= UI =========
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final confPct = _confidence != null
// // //         ? (_confidence! * 100).toStringAsFixed(0)
// // //         : null;
// // //     final divider = Divider(
// // //       height: 1,
// // //       thickness: 1,
// // //       color: Colors.grey.shade200,
// // //     );

// // //     return Scaffold(
// // //       backgroundColor: PoliceBrand.light,
// // //       appBar: CustomAppBar(),
// // //       body: CustomScrollView(
// // //         slivers: [
// // //           // ====== HEADER (style Settings) ======
// // //           SliverToBoxAdapter(
// // //             child: Container(
// // //               margin: const EdgeInsets.all(12),
// // //               padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
// // //               decoration: BoxDecoration(
// // //                 gradient: PoliceBrand.headerGradient,
// // //                 borderRadius: PoliceBrand.radiusLg,
// // //                 image: const DecorationImage(
// // //                   image: AssetImage('assets/img/police_logo.png'),
// // //                   alignment: Alignment(1.2, -1.2),
// // //                   opacity: 0.07,
// // //                   fit: BoxFit.contain,
// // //                 ),
// // //                 boxShadow: const [
// // //                   BoxShadow(
// // //                     color: Colors.black12,
// // //                     blurRadius: 12,
// // //                     offset: Offset(0, 6),
// // //                   ),
// // //                 ],
// // //               ),
// // //               child: Row(
// // //                 children: [
// // //                   Container(
// // //                     width: 62,
// // //                     height: 62,
// // //                     padding: const EdgeInsets.all(8),
// // //                     decoration: BoxDecoration(
// // //                       color: Colors.white,
// // //                       borderRadius: BorderRadius.circular(14),
// // //                       border: Border.all(color: Colors.white, width: 2),
// // //                     ),
// // //                     child: Image.asset('assets/img/police_logo.png'),
// // //                   ),
// // //                   const SizedBox(width: 14),
// // //                   Expanded(
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       children: [
// // //                         Text(
// // //                           "Scan de plaques",
// // //                           style: Theme.of(context).textTheme.titleLarge
// // //                               ?.copyWith(
// // //                                 color: Colors.white,
// // //                                 fontWeight: FontWeight.w800,
// // //                               ),
// // //                         ),
// // //                         const SizedBox(height: 4),
// // //                         Text(
// // //                           _plate == null
// // //                               ? "Prêt pour un contrôle"
// // //                               : "Dernier résultat : $_plate",
// // //                           style: Theme.of(context).textTheme.bodyMedium
// // //                               ?.copyWith(color: Colors.white70, height: 1.3),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                   const SizedBox(width: 6),
// // //                   const _BadgeFlag(),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),

// // //           // ====== CONTENU ======
// // //           SliverToBoxAdapter(
// // //             child: Padding(
// // //               padding: const EdgeInsets.symmetric(horizontal: 12),
// // //               child: Column(
// // //                 children: [
// // //                   // --- Aperçu image + actions
// // //                   _Section(
// // //                     title: "Aperçu",
// // //                     accent: PoliceBrand.primary,
// // //                     children: [
// // //                       AspectRatio(
// // //                         aspectRatio: 16 / 10,
// // //                         child: ClipRRect(
// // //                           borderRadius: PoliceBrand.radiusLg,
// // //                           child: _image != null
// // //                               ? Image.file(_image!, fit: BoxFit.cover)
// // //                               : Container(
// // //                                   color: Colors.grey.shade50,
// // //                                   child: Center(
// // //                                     child: Column(
// // //                                       mainAxisSize: MainAxisSize.min,
// // //                                       children: [
// // //                                         Icon(
// // //                                           Icons.photo_camera_front_outlined,
// // //                                           size: 40,
// // //                                           color: Colors.grey.shade600,
// // //                                         ),
// // //                                         const SizedBox(height: 8),
// // //                                         Text(
// // //                                           'Prendre une photo ou choisir une image',
// // //                                           style: TextStyle(
// // //                                             color: Colors.grey.shade700,
// // //                                           ),
// // //                                         ),
// // //                                       ],
// // //                                     ),
// // //                                   ),
// // //                                 ),
// // //                         ),
// // //                       ),
// // //                       if (_loading) const LinearProgressIndicator(),
// // //                       if (_error != null)
// // //                         Padding(
// // //                           padding: const EdgeInsets.only(top: 10),
// // //                           child: Row(
// // //                             children: [
// // //                               const Icon(
// // //                                 Icons.error_outline,
// // //                                 color: Colors.red,
// // //                               ),
// // //                               const SizedBox(width: 8),
// // //                               Expanded(
// // //                                 child: Text(
// // //                                   'Erreur: $_error',
// // //                                   style: const TextStyle(color: Colors.red),
// // //                                 ),
// // //                               ),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                       const SizedBox(height: 8),
// // //                       Row(
// // //                         children: [
// // //                           Expanded(
// // //                             child: FilledButton.icon(
// // //                               style: FilledButton.styleFrom(
// // //                                 backgroundColor: PoliceBrand.green,
// // //                                 shape: RoundedRectangleBorder(
// // //                                   borderRadius: PoliceBrand.radiusSm,
// // //                                 ),
// // //                               ),
// // //                               onPressed: _loading
// // //                                   ? null
// // //                                   : () => _pickAndRecognize(ImageSource.camera),
// // //                               icon: const Icon(Icons.photo_camera),
// // //                               label: const Text('Caméra'),
// // //                             ),
// // //                           ),
// // //                           const SizedBox(width: 10),
// // //                           Expanded(
// // //                             child: OutlinedButton.icon(
// // //                               style: OutlinedButton.styleFrom(
// // //                                 foregroundColor: PoliceBrand.primary,
// // //                                 side: const BorderSide(
// // //                                   color: PoliceBrand.primary,
// // //                                   width: 1.2,
// // //                                 ),
// // //                                 shape: RoundedRectangleBorder(
// // //                                   borderRadius: PoliceBrand.radiusSm,
// // //                                 ),
// // //                               ),
// // //                               onPressed: _loading
// // //                                   ? null
// // //                                   : () =>
// // //                                         _pickAndRecognize(ImageSource.gallery),
// // //                               icon: const Icon(Icons.photo_library),
// // //                               label: const Text('Galerie'),
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ],
// // //                   ),

// // //                   // --- Résultat & Infos véhicule (STATUT EN PREMIER)
// // //                   _Section(
// // //                     title: "Résultat du scan",
// // //                     accent: PoliceBrand.green,
// // //                     stripeColors: const [
// // //                       PoliceBrand.green,
// // //                       PoliceBrand.yellow,
// // //                       PoliceBrand.red,
// // //                     ],
// // //                     children: [
// // //                       // Plaque + Confiance
// // //                       ListTile(
// // //                         leading: const Icon(Icons.directions_car),
// // //                         title: Text(_plate ?? '—'),
// // //                         subtitle: Text(
// // //                           confPct == null
// // //                               ? 'Confiance —'
// // //                               : 'Confiance $confPct%',
// // //                           style: TextStyle(color: Colors.grey.shade600),
// // //                         ),
// // //                       ),

// // //                       // ===== 1) STATUT DU VÉHICULE (AVANT l’assurance)
// // //                       divider,
// // //                       ListTile(
// // //                         leading: Icon(
// // //                           _statusIcon(_vehicleInfo?.status),
// // //                           color: _statusColor(_vehicleInfo?.status),
// // //                         ),
// // //                         title: const Text('Statut du véhicule'),
// // //                         subtitle: Text(
// // //                           _statusLabelCambrioleFirst(_vehicleInfo?.status),
// // //                           style: TextStyle(
// // //                             color: _statusColor(_vehicleInfo?.status),
// // //                             fontWeight: FontWeight.w700,
// // //                           ),
// // //                         ),
// // //                         trailing: _Pill(
// // //                           icon: _statusIcon(_vehicleInfo?.status),
// // //                           label: _statusLabelCambrioleFirst(
// // //                             _vehicleInfo?.status,
// // //                           ).toUpperCase(),
// // //                           color: _statusColor(_vehicleInfo?.status),
// // //                         ),
// // //                       ),

// // //                       // ===== 2) ASSURANCE (après le statut)
// // //                       divider,
// // //                       Padding(
// // //                         padding: const EdgeInsets.symmetric(
// // //                           horizontal: 12,
// // //                           vertical: 10,
// // //                         ),
// // //                         child: Wrap(
// // //                           spacing: 10,
// // //                           runSpacing: 10,
// // //                           children: [
// // //                             if (_vehicleInfo != null)
// // //                               _Pill(
// // //                                 icon: _vehicleInfo!.assurance
// // //                                     ? Icons.shield
// // //                                     : Icons.shield_outlined,
// // //                                 label:
// // //                                     'Assurance : ${_vehicleInfo!.assurance ? 'OUI' : 'NON'}',
// // //                                 color: _vehicleInfo!.assurance
// // //                                     ? PoliceBrand.green
// // //                                     : PoliceBrand.red,
// // //                               ),
// // //                           ],
// // //                         ),
// // //                       ),
// // //                       if (_vehicleInfo != null) ...[
// // //                         Padding(
// // //                           padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
// // //                           child: Row(
// // //                             children: [
// // //                               const Icon(Icons.today, size: 18),
// // //                               const SizedBox(width: 6),
// // //                               Text(
// // //                                 'Début: ${_fmtDate(_vehicleInfo!.assuranceStart)}',
// // //                               ),
// // //                               const SizedBox(width: 16),
// // //                               const Icon(Icons.event, size: 18),
// // //                               const SizedBox(width: 6),
// // //                               Text(
// // //                                 'Fin: ${_fmtDate(_vehicleInfo!.assuranceEnd)}',
// // //                               ),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                       ],
// // //                       const SizedBox(height: 8),
// // //                     ],
// // //                   ),

// // //                   // (Optionnel) OCR brut — désactivé par défaut
// // //                   // _Section(
// // //                   //   title: "Texte OCR (debug)",
// // //                   //   accent: PoliceBrand.primary,
// // //                   //   children: [
// // //                   //     Padding(
// // //                   //       padding: const EdgeInsets.all(12.0),
// // //                   //       child: SelectableText(
// // //                   //         _text.isEmpty ? '— Résultat OCR —' : _text,
// // //                   //         style: const TextStyle(fontSize: 14),
// // //                   //       ),
// // //                   //     ),
// // //                   //   ],
// // //                   // ),
// // //                   const SizedBox(height: 16),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   String _fmtDate(DateTime? d) => (d == null)
// // //       ? '—'
// // //       : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
// // // }

// // // // ====== Modèle de données véhicule ======
// // // enum VehicleStatus { vole, non_assure, recherche, ok }

// // // class VehicleInfo {
// // //   final String plate;
// // //   final VehicleStatus status;
// // //   final bool assurance;
// // //   final DateTime? assuranceStart;
// // //   final DateTime? assuranceEnd;
// // //   VehicleInfo({
// // //     required this.plate,
// // //     required this.status,
// // //     required this.assurance,
// // //     this.assuranceStart,
// // //     this.assuranceEnd,
// // //   });
// // // }

// // // /// ---------- UI helpers (recyclés de Settings) ----------
// // // class _BadgeFlag extends StatelessWidget {
// // //   const _BadgeFlag();
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return ClipRRect(
// // //       borderRadius: PoliceBrand.radiusSm,
// // //       child: Row(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: const [
// // //           _FlagStripe(color: PoliceBrand.green),
// // //           _FlagStripe(color: PoliceBrand.yellow),
// // //           _FlagStripe(color: PoliceBrand.red),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _FlagStripe extends StatelessWidget {
// // //   final Color color;
// // //   const _FlagStripe({required this.color});
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(width: 8, height: 40, color: color);
// // //   }
// // // }

// // // class _Section extends StatelessWidget {
// // //   final String title;
// // //   final List<Widget> children;
// // //   final Color accent;
// // //   final List<Color>? stripeColors;
// // //   const _Section({
// // //     required this.title,
// // //     required this.children,
// // //     required this.accent,
// // //     this.stripeColors,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final titleRow = Row(
// // //       children: [
// // //         Container(
// // //           width: 4,
// // //           height: 18,
// // //           decoration: BoxDecoration(
// // //             color: accent,
// // //             borderRadius: BorderRadius.circular(2),
// // //           ),
// // //         ),
// // //         const SizedBox(width: 8),
// // //         Text(
// // //           title,
// // //           style: Theme.of(context).textTheme.titleMedium?.copyWith(
// // //             fontWeight: FontWeight.w800,
// // //             color: PoliceBrand.dark,
// // //           ),
// // //         ),
// // //         const Spacer(),
// // //         if (stripeColors != null)
// // //           Row(
// // //             children: stripeColors!
// // //                 .map(
// // //                   (c) => Container(
// // //                     width: 10,
// // //                     height: 10,
// // //                     margin: const EdgeInsets.only(left: 4),
// // //                     decoration: BoxDecoration(
// // //                       color: c,
// // //                       borderRadius: BorderRadius.circular(2),
// // //                     ),
// // //                   ),
// // //                 )
// // //                 .toList(),
// // //           ),
// // //       ],
// // //     );

// // //     final card = Card(
// // //       color: PoliceBrand.surface,
// // //       clipBehavior: Clip.antiAlias,
// // //       elevation: 0,
// // //       shape: RoundedRectangleBorder(borderRadius: PoliceBrand.radiusLg),
// // //       child: Column(children: children),
// // //     );

// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 12),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Padding(
// // //             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
// // //             child: titleRow,
// // //           ),
// // //           card,
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _Pill extends StatelessWidget {
// // //   final IconData icon;
// // //   final String label;
// // //   final Color color;
// // //   const _Pill({required this.icon, required this.label, required this.color});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // //       decoration: BoxDecoration(
// // //         color: color.withOpacity(0.08),
// // //         border: Border.all(color: color.withOpacity(0.35)),
// // //         borderRadius: BorderRadius.circular(999),
// // //       ),
// // //       child: Row(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Icon(icon, size: 16, color: color),
// // //           const SizedBox(width: 6),
// // //           Text(
// // //             label,
// // //             style: TextStyle(color: color, fontWeight: FontWeight.w700),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// // import 'package:niit/ui/screens/settings.dart';
// // import 'package:niit/ui/widgets/app_bar.dart'; // garde-le si tu l'utilises déjà

// // class PlateRecognitionScreen extends StatefulWidget {
// //   const PlateRecognitionScreen({super.key});
// //   @override
// //   State<PlateRecognitionScreen> createState() => _PlateRecognitionScreenState();
// // }

// // class _PlateRecognitionScreenState extends State<PlateRecognitionScreen> {
// //   final _picker = ImagePicker();
// //   final _plateCtrl = TextEditingController();

// //   File? _image;
// //   bool _loading = false;

// //   // OCR brut (debug optionnel)
// //   String _text = '';

// //   // Sortie principale
// //   String? _plate;
// //   double? _confidence; // heuristique locale 0..1

// //   // Infos véhicule
// //   VehicleInfo? _vehicleInfo;

// //   String? _error;

// //   late final TextRecognizer _recognizer = TextRecognizer(
// //     script: TextRecognitionScript.latin,
// //   );

// //   @override
// //   void dispose() {
// //     _recognizer.close();
// //     _plateCtrl.dispose();
// //     super.dispose();
// //   }

// //   // ========= Flux principal : prendre/choisir, OCR, extraire plaque, charger infos =========
// //   Future<void> _pickAndRecognize(ImageSource source) async {
// //     setState(() {
// //       _loading = true;
// //       _error = null;
// //       _text = '';
// //       _plate = null;
// //       _confidence = null;
// //       _vehicleInfo = null;
// //     });

// //     try {
// //       final picked = await _picker.pickImage(source: source, imageQuality: 95);
// //       if (picked == null) {
// //         setState(() => _loading = false);
// //         return;
// //       }

// //       final file = File(picked.path);
// //       setState(() => _image = file);

// //       final inputImage = InputImage.fromFile(file);
// //       final result = await _recognizer.processImage(inputImage);

// //       final buffer = StringBuffer();
// //       for (final block in result.blocks) {
// //         for (final line in block.lines) {
// //           buffer.writeln(line.text);
// //         }
// //       }
// //       final ocrText = buffer.toString().trim();

// //       final normalized = _normalizeOcr(ocrText);
// //       final candidates = _extractPlateCandidates(normalized);
// //       final best = _pickBestCandidate(candidates);

// //       String? plate;
// //       double? conf;
// //       if (best != null) {
// //         plate = best.$1;
// //         conf = best.$2;
// //       }

// //       setState(() {
// //         _text = ocrText;
// //         _plate = plate;
// //         _confidence = conf;
// //         if (plate != null) {
// //           _plateCtrl.text =
// //               plate; // on remplit la zone de saisie avec la détection
// //         }
// //       });

// //       if (plate != null) {
// //         final info = await _loadVehicleInfo(plate);
// //         setState(() => _vehicleInfo = info);
// //       }
// //     } catch (e) {
// //       setState(() => _error = e.toString());
// //     } finally {
// //       setState(() => _loading = false);
// //     }
// //   }

// //   // ========= Recherche par saisie manuelle =========
// //   Future<void> _searchByPlate() async {
// //     FocusScope.of(context).unfocus();
// //     final raw = _plateCtrl.text.trim().toUpperCase();
// //     if (raw.isEmpty) {
// //       setState(() {
// //         _error = "Merci de saisir une plaque (ex: DK-1234-AB)";
// //       });
// //       return;
// //     }
// //     // petite normalisation simple
// //     final plate = raw
// //         .replaceAll(RegExp(r'\s+'), '-')
// //         .replaceAll(RegExp('-{2,}'), '-');

// //     setState(() {
// //       _loading = true;
// //       _error = null;
// //       _text = '';
// //       _plate = plate;
// //       _confidence = 0.95; // on met une confiance élevée car saisie humaine
// //       _vehicleInfo = null;
// //       _image = null; // optionnel: on efface la dernière photo
// //     });

// //     try {
// //       final info = await _loadVehicleInfo(plate);
// //       setState(() => _vehicleInfo = info);
// //     } catch (e) {
// //       setState(() => _error = 'Erreur lors de la recherche: $e');
// //     } finally {
// //       setState(() => _loading = false);
// //     }
// //   }

// //   // ========= MOCK: remplace par tes vrais appels API =========
// //   Future<VehicleInfo> _loadVehicleInfo(String plate) async {
// //     await Future<void>.delayed(const Duration(milliseconds: 300));
// //     if (plate.contains('VOLE')) {
// //       return VehicleInfo(
// //         plate: plate,
// //         status: VehicleStatus.vole,
// //         assurance: false,
// //       );
// //     }
// //     if (plate.contains('NSA') || plate.contains('NONASSURE')) {
// //       return VehicleInfo(
// //         plate: plate,
// //         status: VehicleStatus.non_assure,
// //         assurance: false,
// //       );
// //     }
// //     if (plate.contains('SRCH') || plate.contains('WANTED')) {
// //       return VehicleInfo(
// //         plate: plate,
// //         status: VehicleStatus.recherche,
// //         assurance: true,
// //         assuranceStart: DateTime.now().subtract(const Duration(days: 30)),
// //         assuranceEnd: DateTime.now().add(const Duration(days: 335)),
// //       );
// //     }
// //     final start = DateTime.now().subtract(const Duration(days: 15));
// //     final end = DateTime(start.year + 1, start.month, start.day);
// //     return VehicleInfo(
// //       plate: plate,
// //       status: VehicleStatus.ok,
// //       assurance: true,
// //       assuranceStart: start,
// //       assuranceEnd: end,
// //     );
// //   }

// //   // ========= Utilitaires OCR/Heuristique =========
// //   String _normalizeOcr(String s) {
// //     final up = s.toUpperCase();
// //     return up.replaceAll(RegExp(r'[·•]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
// //   }

// //   final List<RegExp> _platePatterns = [
// //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{3,4}[-\s]?[A-Z]{1,3}\b'),
// //     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{2,4}[-\s]?[A-Z]{1,3}\b'),
// //     RegExp(r'\b\d{2,4}[-\s]?[A-Z]{1,3}[-\s]?\d{2,4}\b'),
// //     RegExp(r'\b[A-Z0-9]{6,10}\b'),
// //   ];

// //   List<String> _extractPlateCandidates(String normalized) {
// //     final List<String> res = [];
// //     for (final rgx in _platePatterns) {
// //       for (final m in rgx.allMatches(normalized)) {
// //         var cand = m.group(0)!;
// //         cand = cand.replaceAll(RegExp(r'\s+'), '-');
// //         cand = cand.replaceAll(RegExp(r'-{2,}'), '-');
// //         res.add(cand);
// //       }
// //     }
// //     final seen = <String>{};
// //     final uniq = <String>[];
// //     for (final c in res) {
// //       if (seen.add(c)) uniq.add(c);
// //     }
// //     return uniq;
// //   }

// //   (String, double)? _pickBestCandidate(List<String> candidates) {
// //     if (candidates.isEmpty) return null;

// //     double scoreOf(String c) {
// //       final s = c.replaceAll('-', '');
// //       if (s.length < 5 || s.length > 10) return 0.1;

// //       final letters = RegExp(r'[A-Z]').allMatches(s).length;
// //       final digits = RegExp(r'\d').allMatches(s).length;
// //       double score = 0.5;

// //       if (letters > 0 && digits > 0) score += 0.2;
// //       if (c.contains('-')) score += 0.1;
// //       if (RegExp(r'(.)\1{2,}').hasMatch(s)) score -= 0.2;
// //       if (s.length >= 7 && s.length <= 8) score += 0.1;

// //       return score.clamp(0, 1);
// //     }

// //     String best = candidates.first;
// //     double bestScore = scoreOf(best);
// //     for (final c in candidates.skip(1)) {
// //       final sc = scoreOf(c);
// //       if (sc > bestScore) {
// //         best = c;
// //         bestScore = sc;
// //       }
// //     }
// //     return (best, bestScore);
// //   }

// //   // ========= Helpers statut (couleur/icone/libellé) =========
// //   Color _statusColor(VehicleStatus? s) {
// //     switch (s) {
// //       case VehicleStatus.vole:
// //         return PoliceBrand.red; // CAMBRIOLÉ
// //       case VehicleStatus.recherche:
// //         return const Color(0xFFEF6C00); // RECHERCHÉ
// //       case VehicleStatus.ok:
// //         return PoliceBrand.green; // OK
// //       case VehicleStatus.non_assure:
// //         return const Color(0xFFFB8C00); // NON ASSURÉ
// //       default:
// //         return Colors.grey.shade700;
// //     }
// //   }

// //   IconData _statusIcon(VehicleStatus? s) {
// //     switch (s) {
// //       case VehicleStatus.vole:
// //         return Icons.report;
// //       case VehicleStatus.recherche:
// //         return Icons.search;
// //       case VehicleStatus.ok:
// //         return Icons.verified;
// //       case VehicleStatus.non_assure:
// //         return Icons.shield;
// //       default:
// //         return Icons.help_outline;
// //     }
// //   }

// //   // Libellé demandé : "cambriolé, ok, recherché"
// //   String _statusLabelCambrioleFirst(VehicleStatus? s) {
// //     switch (s) {
// //       case VehicleStatus.vole:
// //         return 'Cambriolé';
// //       case VehicleStatus.ok:
// //         return 'OK';
// //       case VehicleStatus.recherche:
// //         return 'Recherché';
// //       case VehicleStatus.non_assure:
// //         return 'Non assuré';
// //       default:
// //         return 'Inconnu';
// //     }
// //   }

// //   // ========= UI =========
// //   @override
// //   Widget build(BuildContext context) {
// //     final confPct = _confidence != null
// //         ? (_confidence! * 100).toStringAsFixed(0)
// //         : null;
// //     final divider = Divider(
// //       height: 1,
// //       thickness: 1,
// //       color: Colors.grey.shade200,
// //     );

// //     return Scaffold(
// //       backgroundColor: PoliceBrand.light,
// //       appBar: CustomAppBar(),
// //       body: CustomScrollView(
// //         slivers: [
// //           // ====== HEADER (style Settings) ======
// //           SliverToBoxAdapter(
// //             child: Container(
// //               margin: const EdgeInsets.all(12),
// //               padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
// //               decoration: BoxDecoration(
// //                 gradient: PoliceBrand.headerGradient,
// //                 borderRadius: PoliceBrand.radiusLg,
// //                 image: const DecorationImage(
// //                   image: AssetImage('assets/img/police_logo.png'),
// //                   alignment: Alignment(1.2, -1.2),
// //                   opacity: 0.07,
// //                   fit: BoxFit.contain,
// //                 ),
// //                 boxShadow: const [
// //                   BoxShadow(
// //                     color: Colors.black12,
// //                     blurRadius: 12,
// //                     offset: Offset(0, 6),
// //                   ),
// //                 ],
// //               ),
// //               child: Row(
// //                 children: [
// //                   Container(
// //                     width: 62,
// //                     height: 62,
// //                     padding: const EdgeInsets.all(8),
// //                     decoration: BoxDecoration(
// //                       color: Colors.white,
// //                       borderRadius: BorderRadius.circular(14),
// //                       border: Border.all(color: Colors.white, width: 2),
// //                     ),
// //                     child: Image.asset('assets/img/police_logo.png'),
// //                   ),
// //                   const SizedBox(width: 14),
// //                   Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           "Scan de plaques",
// //                           style: Theme.of(context).textTheme.titleLarge
// //                               ?.copyWith(
// //                                 color: Colors.white,
// //                                 fontWeight: FontWeight.w800,
// //                               ),
// //                         ),
// //                         const SizedBox(height: 4),
// //                         Text(
// //                           _plate == null
// //                               ? "Prêt pour un contrôle"
// //                               : "Dernier résultat : $_plate",
// //                           style: Theme.of(context).textTheme.bodyMedium
// //                               ?.copyWith(color: Colors.white70, height: 1.3),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   const SizedBox(width: 6),
// //                   const _BadgeFlag(),
// //                 ],
// //               ),
// //             ),
// //           ),

// //           // ====== CONTENU ======
// //           SliverToBoxAdapter(
// //             child: Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 12),
// //               child: Column(
// //                 children: [
// //                   // --- Saisie manuelle + actions
// //                   _Section(
// //                     title: "Contrôle",
// //                     accent: PoliceBrand.primary,
// //                     children: [
// //                       // Ligne de saisie de la plaque
// //                       Padding(
// //                         padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
// //                         child: TextField(
// //                           controller: _plateCtrl,
// //                           textCapitalization: TextCapitalization.characters,
// //                           inputFormatters: [
// //                             FilteringTextInputFormatter.allow(
// //                               RegExp(r'[A-Z0-9\-]'),
// //                             ),
// //                             _UpperCaseTextFormatter(),
// //                           ],
// //                           decoration: InputDecoration(
// //                             labelText: 'Plaque du véhicule',
// //                             hintText: 'Ex: DK-1234-AB',
// //                             prefixIcon: const Icon(Icons.onetwothree),
// //                             border: OutlineInputBorder(
// //                               borderRadius: PoliceBrand.radiusSm,
// //                             ),
// //                             filled: true,
// //                             fillColor: Colors.grey.shade50,
// //                           ),
// //                           onSubmitted: (_) => _searchByPlate(),
// //                         ),
// //                       ),
// //                       Padding(
// //                         padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
// //                         child: Row(
// //                           children: [
// //                             Expanded(
// //                               child: FilledButton.icon(
// //                                 style: FilledButton.styleFrom(
// //                                   backgroundColor: PoliceBrand.primary,
// //                                   shape: RoundedRectangleBorder(
// //                                     borderRadius: PoliceBrand.radiusSm,
// //                                   ),
// //                                 ),
// //                                 onPressed: _loading ? null : _searchByPlate,
// //                                 icon: const Icon(Icons.search),
// //                                 label: const Text('Rechercher'),
// //                               ),
// //                             ),
// //                             const SizedBox(width: 10),
// //                             IconButton.filledTonal(
// //                               onPressed: _loading
// //                                   ? null
// //                                   : () => _pickAndRecognize(ImageSource.camera),
// //                               icon: const Icon(Icons.photo_camera),
// //                               tooltip: 'Caméra',
// //                             ),
// //                             const SizedBox(width: 8),
// //                             IconButton.outlined(
// //                               onPressed: _loading
// //                                   ? null
// //                                   : () =>
// //                                         _pickAndRecognize(ImageSource.gallery),
// //                               icon: const Icon(Icons.photo_library_outlined),
// //                               tooltip: 'Galerie',
// //                             ),
// //                           ],
// //                         ),
// //                       ),

// //                       // Aperçu image (si prise via caméra/galerie)
// //                       AspectRatio(
// //                         aspectRatio: 16 / 10,
// //                         child: ClipRRect(
// //                           borderRadius: PoliceBrand.radiusLg,
// //                           child: _image != null
// //                               ? Image.file(_image!, fit: BoxFit.cover)
// //                               : Container(
// //                                   color: Colors.grey.shade50,
// //                                   child: Center(
// //                                     child: Text(
// //                                       'Aucune image — utilisez Caméra, Galerie, ou la saisie manuelle.',
// //                                       style: TextStyle(
// //                                         color: Colors.grey.shade700,
// //                                       ),
// //                                       textAlign: TextAlign.center,
// //                                     ),
// //                                   ),
// //                                 ),
// //                         ),
// //                       ),
// //                       if (_loading) const LinearProgressIndicator(),
// //                       if (_error != null)
// //                         Padding(
// //                           padding: const EdgeInsets.only(
// //                             top: 10,
// //                             left: 12,
// //                             right: 12,
// //                           ),
// //                           child: Row(
// //                             children: [
// //                               const Icon(
// //                                 Icons.error_outline,
// //                                 color: Colors.red,
// //                               ),
// //                               const SizedBox(width: 8),
// //                               Expanded(
// //                                 child: Text(
// //                                   'Erreur: $_error',
// //                                   style: const TextStyle(color: Colors.red),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       const SizedBox(height: 8),
// //                     ],
// //                   ),

// //                   // --- Résultat & Infos véhicule (STATUT EN PREMIER)
// //                   _Section(
// //                     title: "Résultat du scan",
// //                     accent: PoliceBrand.green,
// //                     stripeColors: const [
// //                       PoliceBrand.green,
// //                       PoliceBrand.yellow,
// //                       PoliceBrand.red,
// //                     ],
// //                     children: [
// //                       // Plaque + Confiance
// //                       ListTile(
// //                         leading: const Icon(Icons.directions_car),
// //                         title: Text(_plate ?? '—'),
// //                         subtitle: Text(
// //                           confPct == null
// //                               ? 'Confiance —'
// //                               : 'Confiance $confPct%',
// //                           style: TextStyle(color: Colors.grey.shade600),
// //                         ),
// //                       ),

// //                       // ===== 1) STATUT DU VÉHICULE (AVANT l’assurance)
// //                       divider,
// //                       ListTile(
// //                         leading: Icon(
// //                           _statusIcon(_vehicleInfo?.status),
// //                           color: _statusColor(_vehicleInfo?.status),
// //                         ),
// //                         title: const Text('Statut du véhicule'),
// //                         subtitle: Text(
// //                           _statusLabelCambrioleFirst(_vehicleInfo?.status),
// //                           style: TextStyle(
// //                             color: _statusColor(_vehicleInfo?.status),
// //                             fontWeight: FontWeight.w700,
// //                           ),
// //                         ),
// //                         trailing: _Pill(
// //                           icon: _statusIcon(_vehicleInfo?.status),
// //                           label: _statusLabelCambrioleFirst(
// //                             _vehicleInfo?.status,
// //                           ).toUpperCase(),
// //                           color: _statusColor(_vehicleInfo?.status),
// //                         ),
// //                       ),

// //                       // ===== 2) ASSURANCE (après le statut)
// //                       divider,
// //                       Padding(
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 12,
// //                           vertical: 10,
// //                         ),
// //                         child: Wrap(
// //                           spacing: 10,
// //                           runSpacing: 10,
// //                           children: [
// //                             if (_vehicleInfo != null)
// //                               _Pill(
// //                                 icon: _vehicleInfo!.assurance
// //                                     ? Icons.shield
// //                                     : Icons.shield_outlined,
// //                                 label:
// //                                     'Assurance : ${_vehicleInfo!.assurance ? 'OUI' : 'NON'}',
// //                                 color: _vehicleInfo!.assurance
// //                                     ? PoliceBrand.green
// //                                     : PoliceBrand.red,
// //                               ),
// //                           ],
// //                         ),
// //                       ),
// //                       if (_vehicleInfo != null) ...[
// //                         Padding(
// //                           padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
// //                           child: Row(
// //                             children: [
// //                               const Icon(Icons.today, size: 18),
// //                               const SizedBox(width: 6),
// //                               Text(
// //                                 'Début: ${_fmtDate(_vehicleInfo!.assuranceStart)}',
// //                               ),
// //                               const SizedBox(width: 16),
// //                               const Icon(Icons.event, size: 18),
// //                               const SizedBox(width: 6),
// //                               Text(
// //                                 'Fin: ${_fmtDate(_vehicleInfo!.assuranceEnd)}',
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ],
// //                       const SizedBox(height: 8),
// //                     ],
// //                   ),

// //                   // (Optionnel) OCR brut — désactivé
// //                   // _Section(
// //                   //   title: "Texte OCR (debug)",
// //                   //   accent: PoliceBrand.primary,
// //                   //   children: [
// //                   //     Padding(
// //                   //       padding: const EdgeInsets.all(12.0),
// //                   //       child: SelectableText(
// //                   //         _text.isEmpty ? '— Résultat OCR —' : _text,
// //                   //         style: const TextStyle(fontSize: 14),
// //                   //       ),
// //                   //     ),
// //                   //   ],
// //                   // ),
// //                   const SizedBox(height: 16),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   String _fmtDate(DateTime? d) => (d == null)
// //       ? '—'
// //       : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
// // }

// // // ====== Modèle de données véhicule ======
// // enum VehicleStatus { vole, non_assure, recherche, ok }

// // class VehicleInfo {
// //   final String plate;
// //   final VehicleStatus status;
// //   final bool assurance;
// //   final DateTime? assuranceStart;
// //   final DateTime? assuranceEnd;
// //   VehicleInfo({
// //     required this.plate,
// //     required this.status,
// //     required this.assurance,
// //     this.assuranceStart,
// //     this.assuranceEnd,
// //   });
// // }

// // /// ---------- UI helpers (recyclés de Settings) ----------
// // class _BadgeFlag extends StatelessWidget {
// //   const _BadgeFlag();
// //   @override
// //   Widget build(BuildContext context) {
// //     return ClipRRect(
// //       borderRadius: PoliceBrand.radiusSm,
// //       child: Row(
// //         mainAxisSize: MainAxisSize.min,
// //         children: const [
// //           _FlagStripe(color: PoliceBrand.green),
// //           _FlagStripe(color: PoliceBrand.yellow),
// //           _FlagStripe(color: PoliceBrand.red),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _FlagStripe extends StatelessWidget {
// //   final Color color;
// //   const _FlagStripe({required this.color});
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(width: 8, height: 40, color: color);
// //   }
// // }

// // class _Section extends StatelessWidget {
// //   final String title;
// //   final List<Widget> children;
// //   final Color accent;
// //   final List<Color>? stripeColors;
// //   const _Section({
// //     required this.title,
// //     required this.children,
// //     required this.accent,
// //     this.stripeColors,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     final titleRow = Row(
// //       children: [
// //         Container(
// //           width: 4,
// //           height: 18,
// //           decoration: BoxDecoration(
// //             color: accent,
// //             borderRadius: BorderRadius.circular(2),
// //           ),
// //         ),
// //         const SizedBox(width: 8),
// //         Text(
// //           title,
// //           style: Theme.of(context).textTheme.titleMedium?.copyWith(
// //             fontWeight: FontWeight.w800,
// //             color: PoliceBrand.dark,
// //           ),
// //         ),
// //         const Spacer(),
// //         if (stripeColors != null)
// //           Row(
// //             children: stripeColors!
// //                 .map(
// //                   (c) => Container(
// //                     width: 10,
// //                     height: 10,
// //                     margin: const EdgeInsets.only(left: 4),
// //                     decoration: BoxDecoration(
// //                       color: c,
// //                       borderRadius: BorderRadius.circular(2),
// //                     ),
// //                   ),
// //                 )
// //                 .toList(),
// //           ),
// //       ],
// //     );

// //     final card = Card(
// //       color: PoliceBrand.surface,
// //       clipBehavior: Clip.antiAlias,
// //       elevation: 0,
// //       shape: RoundedRectangleBorder(borderRadius: PoliceBrand.radiusLg),
// //       child: Column(children: children),
// //     );

// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 12),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
// //             child: titleRow,
// //           ),
// //           card,
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _Pill extends StatelessWidget {
// //   final IconData icon;
// //   final String label;
// //   final Color color;
// //   const _Pill({required this.icon, required this.label, required this.color});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// //       decoration: BoxDecoration(
// //         color: color.withOpacity(0.08),
// //         border: Border.all(color: color.withOpacity(0.35)),
// //         borderRadius: BorderRadius.circular(999),
// //       ),
// //       child: Row(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Icon(icon, size: 16, color: color),
// //           const SizedBox(width: 6),
// //           Text(
// //             label,
// //             style: TextStyle(color: color, fontWeight: FontWeight.w700),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // /// Rend tout uppercase au fil de la frappe (ex: dk-1234-ab -> DK-1234-AB)
// // class _UpperCaseTextFormatter extends TextInputFormatter {
// //   @override
// //   TextEditingValue formatEditUpdate(
// //     TextEditingValue oldValue,
// //     TextEditingValue newValue,
// //   ) {
// //     return newValue.copyWith(
// //       text: newValue.text.toUpperCase(),
// //       selection: newValue.selection,
// //     );
// //   }
// // }

// // file: plate_recognition_screen.dart
// //
// // Écran complet POC : scanner / saisir plaques, puis attribuer à chaque plaque
// // un statut + assurance + dates différentes (sans doublons tant que le pool
// // d'alternatives n'est pas épuisé). Conserve caméra / galerie / saisie manuelle.
// // Design épuré reprenant PoliceBrand (présumé défini ailleurs) et CustomAppBar.
// // Remplace les mocks par tes appels réels si besoin.

// import 'dart:io';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:niit/ui/widgets/app_bar.dart'; // garde ou remplace par AppBar si absent

// // ======= Assure-toi que PoliceBrand existe (copie depuis ta page Settings) =======
// // import 'path/to/police_brand.dart';

// class PlateRecognitionScreen extends StatefulWidget {
//   const PlateRecognitionScreen({super.key});

//   @override
//   State<PlateRecognitionScreen> createState() => _PlateRecognitionScreenState();
// }

// class _PlateRecognitionScreenState extends State<PlateRecognitionScreen> {
//   // Pickers / controllers
//   final ImagePicker _picker = ImagePicker();
//   final TextEditingController _plateCtrl = TextEditingController();

//   // OCR
//   late final TextRecognizer _recognizer = TextRecognizer(
//     script: TextRecognitionScript.latin,
//   );

//   // UI state
//   File? _image;
//   bool _loading = false;
//   String? _error;

//   // POC assignments
//   final Map<String, VehicleInfo> _assigned = {}; // plaque -> assigned info
//   final List<_Combo> _baseCombos = [
//     // pool d'alternatives (statut, assurancePossible)
//     _Combo(VehicleStatus.ok, true),
//     _Combo(VehicleStatus.ok, false),
//     _Combo(VehicleStatus.recherche, true),
//     _Combo(VehicleStatus.recherche, false),
//     _Combo(VehicleStatus.vole, false),
//     _Combo(VehicleStatus.non_assure, false),
//     _Combo(VehicleStatus.ok, true),
//     _Combo(VehicleStatus.recherche, true),
//     _Combo(
//       VehicleStatus.vole,
//       true,
//     ), // possibilité: volé mais renseigné assurance true
//   ];
//   late List<_Combo> _comboQueue;
//   final Random _rng = Random();

//   // History (recent scans / recherches)
//   final List<String> _history = []; // liste des plaques dans l'ordre

//   // OCR helper (kept for camera / gallery usage)
//   final List<RegExp> _platePatterns = [
//     RegExp(r'\b[A-Z]{1,3}[-\s]?\d{2,4}[-\s]?[A-Z]{0,3}\b'),
//     RegExp(r'\b[A-Z0-9\-]{5,10}\b'),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _reshuffleCombos();
//   }

//   void _reshuffleCombos() {
//     _comboQueue = List<_Combo>.from(_baseCombos)..shuffle(_rng);
//   }

//   @override
//   void dispose() {
//     _recognizer.close();
//     _plateCtrl.dispose();
//     super.dispose();
//   }

//   // ===================== Core: assign a unique combo to a plate =====================
//   VehicleInfo _assignRandomInfoForPlate(String plate) {
//     // If already assigned, return same info (consistence)
//     final key = plate.toUpperCase();
//     if (_assigned.containsKey(key)) return _assigned[key]!;

//     // If queue empty, reshuffle (re-use combos in new random order)
//     if (_comboQueue.isEmpty) _reshuffleCombos();

//     // Pop one combo
//     final combo = _comboQueue.removeLast();

//     // Generate assurance dates based on combo.assurancePossible and randomness
//     DateTime? start;
//     DateTime? end;
//     bool assurance = combo.assured;
//     if (assurance) {
//       // choose a random start within last 365 days, duration 180-540 days
//       final daysBack = _rng.nextInt(180); // 0..179
//       start = DateTime.now().subtract(Duration(days: daysBack));
//       final dur = 180 + _rng.nextInt(365); // between 180 and 544 days
//       end = start.add(Duration(days: dur));
//     }

//     // Create VehicleInfo and store
//     final info = VehicleInfo(
//       plate: key,
//       status: combo.status,
//       assurance: assurance,
//       assuranceStart: start,
//       assuranceEnd: end,
//     );
//     _assigned[key] = info;
//     return info;
//   }

//   // ===================== Camera / Gallery OCR flow =====================
//   Future<void> _pickAndRecognize(ImageSource source) async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       final picked = await _picker.pickImage(source: source, imageQuality: 90);
//       if (picked == null) {
//         setState(() => _loading = false);
//         return;
//       }

//       final file = File(picked.path);
//       setState(() {
//         _image = file;
//       });

//       final inputImage = InputImage.fromFile(file);
//       final result = await _recognizer.processImage(inputImage);

//       // build OCR text
//       final buffer = StringBuffer();
//       for (final block in result.blocks) {
//         for (final line in block.lines) {
//           buffer.writeln(line.text);
//         }
//       }
//       final ocrText = buffer.toString().toUpperCase();

//       // try to extract candidate plates
//       final candidates = <String>[];
//       for (final rgx in _platePatterns) {
//         for (final m in rgx.allMatches(ocrText)) {
//           var cand = m.group(0)!.trim();
//           cand = cand.replaceAll(RegExp(r'\s+'), '-');
//           cand = cand.replaceAll(RegExp(r'-{2,}'), '-');
//           candidates.add(cand);
//         }
//       }

//       // choose best candidate heuristically (longer preferred)
//       String chosen;
//       if (candidates.isEmpty) {
//         setState(() {
//           _error = 'Aucune plaque détectée — essaie la saisie manuelle';
//         });
//         setState(() => _loading = false);
//         return;
//       } else {
//         candidates.sort((a, b) => b.length.compareTo(a.length));
//         chosen = candidates.first;
//       }

//       // assign info (POC unique per plate)
//       final info = _assignRandomInfoForPlate(chosen);

//       // update UI + history
//       setState(() {
//         _plateCtrl.text = chosen;
//         if (!_history.contains(chosen)) _history.insert(0, chosen);
//         _image = file;
//         _error = null;
//       });

//       // optional: small delay to simulate network
//       await Future.delayed(const Duration(milliseconds: 150));
//       // show assigned info (we'll show using bottom sheet)
//       _showInfoForPlate(info);
//     } catch (e) {
//       setState(() => _error = 'OCR error: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   // ===================== Manual search / add =====================
//   Future<void> _searchByPlateManual() async {
//     final raw = _plateCtrl.text.trim().toUpperCase();
//     if (raw.isEmpty) {
//       setState(() {
//         _error = 'Saisis une plaque (ex: DK-1234-AB)';
//       });
//       return;
//     }
//     final plate = raw
//         .replaceAll(RegExp(r'\s+'), '-')
//         .replaceAll(RegExp('-{2,}'), '-');
//     setState(() {
//       _loading = true;
//       _error = null;
//       _image = null;
//     });

//     // assign
//     final info = _assignRandomInfoForPlate(plate);
//     if (!_history.contains(plate)) _history.insert(0, plate);

//     // small delay
//     await Future.delayed(const Duration(milliseconds: 150));
//     setState(() => _loading = false);
//     _showInfoForPlate(info);
//   }

//   // ===================== Add multiple plates at once (POC) =====================
//   Future<void> _addMultiplePlatesSheet() async {
//     final ctrl = TextEditingController();
//     final res = await showModalBottomSheet<bool>(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(ctx).viewInsets.bottom,
//           ),
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Ajouter plusieurs plaques (séparées par virgule ou newline)',
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: ctrl,
//                   keyboardType: TextInputType.multiline,
//                   maxLines: 4,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.allow(
//                       RegExp(r'[A-Za-z0-9\-\s,]'),
//                     ),
//                   ],
//                   decoration: const InputDecoration(
//                     hintText: 'Ex: DK-1234-AB, SN-9999-XY\nDK-4321-ZT',
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: FilledButton(
//                         onPressed: () {
//                           Navigator.of(ctx).pop(true);
//                         },
//                         child: const Text('Ajouter'),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     OutlinedButton(
//                       onPressed: () => Navigator.of(ctx).pop(false),
//                       child: const Text('Annuler'),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//               ],
//             ),
//           ),
//         );
//       },
//     );

//     if (res != true) return;
//     final text = ctrl.text.trim();
//     if (text.isEmpty) return;

//     final parts = text
//         .split(RegExp(r'[,\n]+'))
//         .map((s) => s.trim().toUpperCase())
//         .where((s) => s.isNotEmpty);
//     for (final raw in parts) {
//       final plate = raw
//           .replaceAll(RegExp(r'\s+'), '-')
//           .replaceAll(RegExp('-{2,}'), '-');
//       final info = _assignRandomInfoForPlate(plate);
//       if (!_history.contains(plate)) _history.insert(0, plate);
//       // small pause to avoid UI freeze
//       await Future<void>.delayed(const Duration(milliseconds: 80));
//       // optionally show snackbar per added
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Ajout: $plate → ${_labelFromStatus(info.status)}'),
//         ),
//       );
//     }

//     setState(() {});
//   }

//   // ===================== UI helpers =====================
//   void _showInfoForPlate(VehicleInfo info) {
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) {
//         return Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     _iconFromStatus(info.status),
//                     color: _colorFromStatus(info.status),
//                     size: 28,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       info.plate,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ),
//                   Chip(
//                     label: Text(_labelFromStatus(info.status).toUpperCase()),
//                     backgroundColor: _colorFromStatus(
//                       info.status,
//                     ).withOpacity(0.12),
//                     side: BorderSide(
//                       color: _colorFromStatus(info.status).withOpacity(0.28),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Icon(
//                     info.assurance ? Icons.shield : Icons.shield_outlined,
//                     color: info.assurance ? Colors.green : Colors.orange,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Assurance: ${info.assurance ? "OUI" : "NON"}',
//                     style: const TextStyle(fontWeight: FontWeight.w700),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   const Icon(Icons.today, size: 18),
//                   const SizedBox(width: 8),
//                   Text('Début: ${_fmtDate(info.assuranceStart)}'),
//                   const SizedBox(width: 16),
//                   const Icon(Icons.event, size: 18),
//                   const SizedBox(width: 8),
//                   Text('Fin: ${_fmtDate(info.assuranceEnd)}'),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: FilledButton.tonal(
//                       onPressed: () {
//                         Navigator.of(ctx).pop();
//                         // Action POC : enregistrer / partager / notifier
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'Constat sauvegardé pour ${info.plate} (POC)',
//                             ),
//                           ),
//                         );
//                       },
//                       child: const Text('Enregistrer constat'),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   OutlinedButton(
//                     onPressed: () {
//                       Navigator.of(ctx).pop();
//                     },
//                     child: const Text('Fermer'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ===================== Small UI utilities =====================
//   Color _colorFromStatus(VehicleStatus s) {
//     switch (s) {
//       case VehicleStatus.ok:
//         return Colors.green.shade700;
//       case VehicleStatus.recherche:
//         return Colors.deepOrange.shade700;
//       case VehicleStatus.vole:
//         return Colors.red.shade700;
//       case VehicleStatus.non_assure:
//         return Colors.orange.shade700;
//     }
//   }

//   IconData _iconFromStatus(VehicleStatus s) {
//     switch (s) {
//       case VehicleStatus.ok:
//         return Icons.verified;
//       case VehicleStatus.recherche:
//         return Icons.search;
//       case VehicleStatus.vole:
//         return Icons.report;
//       case VehicleStatus.non_assure:
//         return Icons.security;
//     }
//   }

//   String _labelFromStatus(VehicleStatus s) {
//     switch (s) {
//       case VehicleStatus.ok:
//         return 'OK';
//       case VehicleStatus.recherche:
//         return 'RECHERCHÉ';
//       case VehicleStatus.vole:
//         return 'CAMBRIOLÉ';
//       case VehicleStatus.non_assure:
//         return 'NON ASSURÉ';
//     }
//   }

//   String _fmtDate(DateTime? d) {
//     if (d == null) return '—';
//     return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
//   }

//   // ===================== Build UI =====================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             children: [
//               // Input row: manual plate + search + multi-add
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _plateCtrl,
//                       textCapitalization: TextCapitalization.characters,
//                       inputFormatters: [
//                         FilteringTextInputFormatter.allow(
//                           RegExp(r'[A-Za-z0-9\-\s]'),
//                         ),
//                         UpperCaseFormatter(),
//                       ],
//                       decoration: const InputDecoration(
//                         labelText: 'Plaque (manuelle)',
//                         hintText: 'Ex: DK-1234-AB',
//                         border: OutlineInputBorder(),
//                       ),
//                       onSubmitted: (_) => _searchByPlateManual(),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   FilledButton.icon(
//                     onPressed: _loading ? null : _searchByPlateManual,
//                     icon: const Icon(Icons.search),
//                     label: const Text('Rechercher'),
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton(
//                     tooltip: 'Ajouter plusieurs plaques',
//                     onPressed: _addMultiplePlatesSheet,
//                     icon: const Icon(Icons.playlist_add),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),

//               // Camera / gallery buttons
//               Row(
//                 children: [
//                   Expanded(
//                     child: FilledButton.icon(
//                       onPressed: _loading
//                           ? null
//                           : () => _pickAndRecognize(ImageSource.camera),
//                       icon: const Icon(Icons.photo_camera),
//                       label: const Text('Caméra'),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: _loading
//                           ? null
//                           : () => _pickAndRecognize(ImageSource.gallery),
//                       icon: const Icon(Icons.photo_library),
//                       label: const Text('Galerie'),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),

//               // Error / loading
//               if (_loading) const LinearProgressIndicator(),
//               if (_error != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8.0),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.error_outline, color: Colors.red),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           _error!,
//                           style: const TextStyle(color: Colors.red),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//               const SizedBox(height: 12),

//               // Recent history list
//               Expanded(
//                 child: Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Historique (scans / recherches récentes)',
//                           style: TextStyle(fontWeight: FontWeight.w700),
//                         ),
//                         const SizedBox(height: 8),
//                         Expanded(
//                           child: _history.isEmpty
//                               ? const Center(
//                                   child: Text(
//                                     'Aucune plaque pour l’instant — scanne ou ajoute',
//                                   ),
//                                 )
//                               : ListView.separated(
//                                   itemCount: _history.length,
//                                   separatorBuilder: (_, __) => const Divider(),
//                                   itemBuilder: (ctx, i) {
//                                     final plate = _history[i];
//                                     final info = _assigned[plate];
//                                     return ListTile(
//                                       leading: CircleAvatar(
//                                         backgroundColor: info == null
//                                             ? Colors.grey.shade300
//                                             : _colorFromStatus(
//                                                 info.status,
//                                               ).withOpacity(0.18),
//                                         child: Icon(
//                                           info == null
//                                               ? Icons.shield
//                                               : _iconFromStatus(info.status),
//                                           color: info == null
//                                               ? Colors.grey
//                                               : _colorFromStatus(info.status),
//                                         ),
//                                       ),
//                                       title: Text(plate),
//                                       subtitle: Text(
//                                         info == null
//                                             ? '—'
//                                             : 'Statut: ${_labelFromStatus(info.status)} • Assurance: ${info.assurance ? "OUI" : "NON"}',
//                                       ),
//                                       trailing: Row(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           IconButton(
//                                             tooltip: 'Voir détails',
//                                             icon: const Icon(
//                                               Icons.chevron_right,
//                                             ),
//                                             onPressed: info == null
//                                                 ? null
//                                                 : () => _showInfoForPlate(info),
//                                           ),
//                                           IconButton(
//                                             tooltip: 'Retirer',
//                                             icon: const Icon(
//                                               Icons.delete_outline,
//                                             ),
//                                             onPressed: () {
//                                               setState(() {
//                                                 _assigned.remove(plate);
//                                                 _history.removeAt(i);
//                                               });
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 ),
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           children: [
//                             FilledButton.tonal(
//                               onPressed: () {
//                                 // reset POC (clear assignments and reshuffle)
//                                 setState(() {
//                                   _assigned.clear();
//                                   _history.clear();
//                                   _reshuffleCombos();
//                                 });
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text('POC réinitialisé'),
//                                   ),
//                                 );
//                               },
//                               child: const Text('Réinitialiser le POC'),
//                             ),
//                             const SizedBox(width: 8),
//                             OutlinedButton(
//                               onPressed: () {
//                                 // show assigned map size
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text(
//                                       '${_assigned.length} plaques assignées',
//                                     ),
//                                   ),
//                                 );
//                               },
//                               child: const Text('Statistiques'),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ===================== Small models & helpers =====================

// class _Combo {
//   final VehicleStatus status;
//   final bool assured; // whether insurance should be true for this combo
//   _Combo(this.status, this.assured);
// }

// enum VehicleStatus { ok, recherche, vole, non_assure }

// class VehicleInfo {
//   final String plate;
//   final VehicleStatus status;
//   final bool assurance;
//   final DateTime? assuranceStart;
//   final DateTime? assuranceEnd;

//   VehicleInfo({
//     required this.plate,
//     required this.status,
//     required this.assurance,
//     this.assuranceStart,
//     this.assuranceEnd,
//   });
// }

// /// Formatter to uppercase while typing
// class UpperCaseFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     return newValue.copyWith(
//       text: newValue.text.toUpperCase(),
//       selection: newValue.selection,
//     );
//   }
// }

// file: plate_recognition_screen.dart
//
// Écran POC "Contrôle des véhicules" au style de settings.dart :
// - Header gradient + ruban drapeau
// - Sections (barrette d’accent) + cartes blanches
// - Saisie manuelle (et ajout en lot)
// - Scan via Caméra/Galerie (OCR ML Kit)
// - Pour un POC : attribution aléatoire SANS doublons des couples (statut, assurance)
//   pour chaque nouvelle plaque jusqu’à épuisement du pool (puis on rebrasse)
//
// Prérequis :
//   dependencies:
//     image_picker: ^1.0.0
//     google_mlkit_text_recognition: ^0.13.0  (ou récent compatible)
//   iOS: faire `pod repo update` si conflit de versions
//
// Assets:
//   - assets/img/police_logo.png  (comme dans settings)
//
// NOTE : Ce fichier attend :
//   import 'package:niit/ui/widgets/app_bar.dart' (CustomAppBar)
//   PoliceBrand (depuis ta page settings.dart)

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
  // ---- IO / OCR
  final _picker = ImagePicker();
  late final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // ---- Inputs
  final _plateCtrl = TextEditingController();

  // ---- UI state
  bool _loading = false;
  String? _error;
  File? _image;

  // ---- POC: attribution unique (statut, assurance) par plaque jusqu'à épuisement du pool
  final Map<String, VehicleInfo> _assigned = {}; // plaque -> info
  final List<String> _history = []; // ordre d’ajout
  final _rng = Random();

  // Pool de combinaisons (statut, assurance) sans doublons
  // (on évite que deux plaques différentes aient le même couple tant que le pool n’est pas vidé)
  final List<_Combo> _baseCombos = const [
    _Combo(VehicleStatus.ok, true),
    _Combo(VehicleStatus.ok, false),
    _Combo(VehicleStatus.recherche, true),
    _Combo(VehicleStatus.recherche, false),
    _Combo(VehicleStatus.vole, false),
    _Combo(VehicleStatus.non_assure, false),
    _Combo(
      VehicleStatus.vole,
      true,
    ), // variante pour montrer "volé" + assurance
    _Combo(VehicleStatus.ok, true),
    _Combo(VehicleStatus.recherche, true),
  ];
  late List<_Combo> _comboQueue = [];

  // OCR helpers
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

  // =======================================================================================
  //                                  ACTIONS UTILISATEUR
  // =======================================================================================

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
    // Affiche la fiche du véhicule ajouté
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

  // Future<void> _pickAndRecognize(ImageSource source) async {
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //     _image = null;
  //   });

  //   try {
  //     final picked = await _picker.pickImage(source: source, imageQuality: 95);
  //     if (picked == null) {
  //       setState(() => _loading = false);
  //       return;
  //     }
  //     final file = File(picked.path);
  //     setState(() => _image = file);

  //     final inputImage = InputImage.fromFile(file);
  //     final result = await _recognizer.processImage(inputImage);

  //     final buffer = StringBuffer();
  //     for (final block in result.blocks) {
  //       for (final line in block.lines) {
  //         buffer.writeln(line.text);
  //       }
  //     }
  //     final ocrText = buffer.toString().toUpperCase();

  //     final normalized = _normalizeOcr(ocrText);
  //     final candidates = _extractPlateCandidates(normalized);
  //     final best = _pickBestCandidate(candidates);

  //     if (best == null) {
  //       setState(() => _error = "Aucune plaque détectée.");
  //     } else {
  //       final plate = best.$1;
  //       _assignIfNeeded(plate);
  //       // Affiche la fiche du véhicule ajouté
  //       final info = _assigned[plate]!;
  //       _showInfoForPlate(info);
  //     }
  //   } catch (e) {
  //     setState(() => _error = "Erreur OCR: $e");
  //   } finally {
  //     setState(() => _loading = false);
  //   }
  // }
  Future<void> _pickAndRecognize(ImageSource source) async {
    setState(() {
      _error = null;
      _image = null; // on repart propre
    });

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 95);
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _image = file; // 👉 on montre la photo immédiatement
        _loading = true; // 👉 on affiche le loader
      });

      VehicleInfo? infoToShow;

      // OCR + extraction plaque (tâche 1)
      final inputImage = InputImage.fromFile(file);
      final ocrTask = () async {
        final result = await _recognizer.processImage(inputImage);

        // OCR → texte
        final buffer = StringBuffer();
        for (final block in result.blocks) {
          for (final line in block.lines) {
            buffer.writeln(line.text);
          }
        }
        final ocrText = buffer.toString().toUpperCase();

        // extraction plaque
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

      // Timer 3s (tâche 2)
      final minimumDelay = Future.delayed(const Duration(seconds: 3));

      // On attend la fin des 2 tâches
      await Future.wait([ocrTask, minimumDelay]);

      if (!mounted) return;
      setState(() => _loading = false);

      if (infoToShow != null) {
        _showInfoForPlate(infoToShow!);
      } else if (_error != null) {
        // Affiche un message si pas de plaque trouvée
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

  // =======================================================================================
  //                             ATTRIBUTION POC (sans doublons)
  // =======================================================================================

  void _assignIfNeeded(String plate) {
    if (_assigned.containsKey(plate)) {
      // déjà attribué, on remonte juste en tête d'historique
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
      // Assurance active : début il y a 0..60 jours, fin dans ~10..13 mois
      final startOffset = _rng.nextInt(61); // 0..60
      start = DateTime.now().subtract(Duration(days: startOffset));
      final months = 10 + _rng.nextInt(4); // 10..13
      end = DateTime(start.year, start.month + months, start.day);
    } else {
      // Non assuré : 50% jamais assuré, 50% expiré récemment
      if (_rng.nextBool()) {
        start = null;
        end = null;
      } else {
        final endOffset = 5 + _rng.nextInt(60); // expiré depuis 5..64 jours
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

  // =======================================================================================
  //                               OCR / Extraction plaque
  // =======================================================================================

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
    candidates.sort(
      (a, b) => b.length.compareTo(a.length),
    ); // heuristique simple
    final best = candidates.first;
    return (best, 0.9);
  }

  // =======================================================================================
  //                                         UI
  // =======================================================================================

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
              // ====== HEADER (style Settings) ======
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
                            const SizedBox(height: 4),
                            Text(
                              "POC • Statuts & assurances alternés (sans doublons)",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                    height: 1.3,
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
                        title: "Saisie & Scan",
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
                                prefixIcon: const Icon(Icons.onetwothree),
                                border: OutlineInputBorder(
                                  borderRadius: PoliceBrand.radiusSm,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
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
                                    icon: const Icon(Icons.add),
                                    label: const Text('Ajouter'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // OutlinedButton.icon(
                                //   onPressed: _loading ? null : _openBulkAdder,
                                //   icon: const Icon(Icons.playlist_add),
                                //   label: const Text("Ajouter plusieurs"),
                                //   style: OutlinedButton.styleFrom(
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: PoliceBrand.radiusSm,
                                //     ),
                                //   ),
                                // ),
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
                                "Aucun véhicule. Ajoute une plaque (saisie) ou scanne via Caméra/Galerie.",
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
                                        content: Text('POC réinitialisé'),
                                      ),
                                    );
                                  },
                                  child: const Text('Réinitialiser le POC'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
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
                  Icon(icon, color: color, size: 28),
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
                    icon: icon,
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
                    icon: info.assurance ? Icons.shield : Icons.shield_outlined,
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
                              'Constat sauvegardé pour ${info.plate} (POC)',
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
        return Icons.shield_outlined; // ✅ icône dispo sur stable
    }
  }

  String _statusLabel(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.vole:
        return 'Cambriolé';
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

// =======================================================================================
//                                        WIDGETS
// =======================================================================================

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
                icon: icon,
                label: _statusLabel(info.status).toUpperCase(),
                color: color,
              ),
              _Pill(
                icon: info.assurance ? Icons.shield : Icons.shield_outlined,
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
        return 'Cambriolé';
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

// ---- Bottom sheet: ajouter plusieurs plaques
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
                // Row(
                //   children: [
                //     Text(
                //       "Ajouter plusieurs plaques",
                //       style: Theme.of(context).textTheme.titleMedium,
                //     ),
                //     const Spacer(),
                //     IconButton(
                //       icon: const Icon(Icons.close),
                //       onPressed: () => Navigator.pop(context),
                //     ),
                //   ],
                // ),
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

// ---- Aides visuelles (reprennent la patte Settings)
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
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

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
          Icon(icon, size: 16, color: color),
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

// =======================================================================================
//                                   DONNÉES / MODÈLES
// =======================================================================================

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

// =======================================================================================
//                                      HELPERS
// =======================================================================================

/// Uppercase à la frappe
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
// ===================== LOADER JOLI : Overlay + Spinner =====================

class _LoadingOverlay extends StatelessWidget {
  final String? message;
  const _LoadingOverlay({this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // flou + voile
          Container(color: Colors.black.withOpacity(0.25)),
          // Contenu centré
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
          // Anneau animé
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
          // Médaillon logo
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
    final start = -90.0 * (3.14159 / 180.0); // commence en haut

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

    // anneau discret de fond
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

    // arc principal (3/4 de cercle)
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
