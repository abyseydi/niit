import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ZoneLevel { low, medium, high, critical }

enum ZoneStatus { active, paused, archived }

class RedZone {
  final String id;
  String name;
  ZoneLevel level;
  ZoneStatus status;
  DateTime createdAt;
  DateTime lastUpdate;
  String reason;
  List<String> affectedStreets;
  List<Offset> polygon; // coordonnées normalisées [0..1]

  RedZone({
    required this.id,
    required this.name,
    required this.level,
    required this.status,
    required this.createdAt,
    required this.lastUpdate,
    required this.reason,
    required this.affectedStreets,
    required this.polygon,
  });

  RedZone copyWith({
    String? name,
    ZoneLevel? level,
    ZoneStatus? status,
    DateTime? createdAt,
    DateTime? lastUpdate,
    String? reason,
    List<String>? affectedStreets,
    List<Offset>? polygon,
  }) {
    return RedZone(
      id: id,
      name: name ?? this.name,
      level: level ?? this.level,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      reason: reason ?? this.reason,
      affectedStreets: affectedStreets ?? this.affectedStreets,
      polygon: polygon ?? this.polygon,
    );
  }
}

class ZonesRougesPage extends StatefulWidget {
  const ZonesRougesPage({super.key});
  @override
  State<ZonesRougesPage> createState() => _ZonesRougesPageState();
}

class _ZonesRougesPageState extends State<ZonesRougesPage>
    with TickerProviderStateMixin {
  // --------- Données mock ---------
  final List<RedZone> _zones = [
    RedZone(
      id: 'z1',
      name: 'Colobane – Marché',
      level: ZoneLevel.high,
      status: ZoneStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 30)),
      reason: 'Risque de rassemblements & altercations signalés',
      affectedStreets: ['Av. Cheikh Anta Diop', 'Allées Marché'],
      polygon: const [
        Offset(0.18, 0.18),
        Offset(0.30, 0.20),
        Offset(0.32, 0.30),
        Offset(0.20, 0.34),
      ],
    ),
    RedZone(
      id: 'z2',
      name: 'Corniche Ouest – Fann',
      level: ZoneLevel.medium,
      status: ZoneStatus.paused,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      lastUpdate: DateTime.now().subtract(const Duration(hours: 3)),
      reason: 'Accidents récurrents en soirée (travaux)',
      affectedStreets: ['Corniche Ouest', 'Boulevard de la Mer'],
      polygon: const [
        Offset(0.60, 0.60),
        Offset(0.78, 0.58),
        Offset(0.82, 0.72),
        Offset(0.66, 0.76),
      ],
    ),
    RedZone(
      id: 'z3',
      name: 'Point E – Stade',
      level: ZoneLevel.low,
      status: ZoneStatus.archived,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      lastUpdate: DateTime.now().subtract(const Duration(days: 1)),
      reason: 'Événement terminé',
      affectedStreets: ['Rue A', 'Rue B'],
      polygon: const [
        Offset(0.40, 0.28),
        Offset(0.52, 0.30),
        Offset(0.54, 0.40),
        Offset(0.42, 0.42),
      ],
    ),
  ];

  // --------- État UI ---------
  final _searchCtrl = TextEditingController();
  ZoneLevel? _levelFilter;
  ZoneStatus? _statusFilter;
  bool _sortNewestFirst = true;

  // Glow header + tick pour carte
  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  Timer? _tick;
  double _t = 0;

  // Position “moi”
  Offset _me = const Offset(0.45, 0.55);
  double _azimuth = 0;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 60), (_) {
      setState(() {
        _t += 0.016;
        _azimuth = (_azimuth + 0.01) % (2 * pi);
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _glowCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // --------- Helpers ---------
  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'à l’instant';
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays} j';
  }

  Color _levelColor(ZoneLevel l) {
    switch (l) {
      case ZoneLevel.low:
        return Colors.teal;
      case ZoneLevel.medium:
        return Colors.amber.shade700;
      case ZoneLevel.high:
        return Colors.redAccent;
      case ZoneLevel.critical:
        return const Color(0xFFD93025);
    }
  }

  String _levelLabel(ZoneLevel l) {
    switch (l) {
      case ZoneLevel.low:
        return 'Faible';
      case ZoneLevel.medium:
        return 'Moyen';
      case ZoneLevel.high:
        return 'Élevé';
      case ZoneLevel.critical:
        return 'Critique';
    }
  }

  Color _statusColor(ZoneStatus s) {
    switch (s) {
      case ZoneStatus.active:
        return Colors.green;
      case ZoneStatus.paused:
        return Colors.blueAccent;
      case ZoneStatus.archived:
        return Colors.grey;
    }
  }

  // --------- KPIs ---------
  int get _kpiActive =>
      _zones.where((z) => z.status == ZoneStatus.active).length;
  int get _kpiPaused =>
      _zones.where((z) => z.status == ZoneStatus.paused).length;
  int get _kpiTotal => _zones.length;

  // --------- Filtrage ---------
  List<RedZone> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _zones.where((z) {
      if (_levelFilter != null && z.level != _levelFilter) return false;
      if (_statusFilter != null && z.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      final hay = [
        z.name,
        z.reason,
        ...z.affectedStreets,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();

    list.sort(
      (a, b) => _sortNewestFirst
          ? b.lastUpdate.compareTo(a.lastUpdate)
          : a.lastUpdate.compareTo(b.lastUpdate),
    );
    return list;
  }

  // --------- Actions ---------
  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _toggleActive(RedZone z) {
    setState(() {
      z.status = z.status == ZoneStatus.active
          ? ZoneStatus.paused
          : ZoneStatus.active;
      z.lastUpdate = DateTime.now();
    });
    _snack(
      z.status == ZoneStatus.active ? 'Zone activée' : 'Zone mise en pause',
    );
  }

  void _archive(RedZone z) {
    setState(() {
      z.status = ZoneStatus.archived;
      z.lastUpdate = DateTime.now();
    });
    _snack('Zone archivée');
  }

  void _delete(RedZone z) {
    setState(() => _zones.removeWhere((x) => x.id == z.id));
    _snack('Zone supprimée');
  }

  void _notifyUnits(RedZone z) =>
      _snack('Notification envoyée aux unités (mock)');
  void _simulateEditPolygon(RedZone z) => _snack('Édition du périmètre (mock)');

  void _createZoneDialog() {
    final name = TextEditingController();
    ZoneLevel level = ZoneLevel.medium;
    final reason = TextEditingController();
    final streets = TextEditingController(text: 'Rue Exemple 1, Rue Exemple 2');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvelle zone rouge'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ZoneLevel>(
                value: level,
                decoration: const InputDecoration(labelText: 'Niveau'),
                items: ZoneLevel.values
                    .map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text(_levelLabel(l)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => level = v ?? level,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reason,
                decoration: const InputDecoration(labelText: 'Motif / Raison'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: streets,
                decoration: const InputDecoration(
                  labelText: 'Rues impactées (séparées par des virgules)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              setState(() {
                _zones.insert(
                  0,
                  RedZone(
                    id: 'z${DateTime.now().millisecondsSinceEpoch}',
                    name: name.text.trim(),
                    level: level,
                    status: ZoneStatus.active,
                    createdAt: DateTime.now(),
                    lastUpdate: DateTime.now(),
                    reason: reason.text.trim().isEmpty
                        ? '—'
                        : reason.text.trim(),
                    affectedStreets: streets.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                    polygon: const [
                      Offset(0.35, 0.35),
                      Offset(0.48, 0.34),
                      Offset(0.52, 0.46),
                      Offset(0.40, 0.48),
                    ],
                  ),
                );
              });
              Navigator.pop(context);
              _snack('Zone créée');
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  // --------- Build ---------
  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: CustomScrollView(
        slivers: [
          // ===== Header IA =====
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment(-0.9, -1),
                  end: Alignment(0.9, 1),
                  colors: [Color(0xFF111111), Color(0xFF1E1E1E)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _glowCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _AiGlowPainter(
                          intensity: 0.55 + 0.45 * _glowCtrl.value,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (r) => const LinearGradient(
                                  colors: [Colors.white, Color(0xFFBDE6FF)],
                                ).createShader(r),
                                child: const Text(
                                  'Zones rouges',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$_kpiActive actives • $_kpiPaused en pause • $_kpiTotal total',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HeaderAction(
                          icon: Icons.add_circle_outline,
                          tooltip: 'Créer une zone',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _createZoneDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== KPIs =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: 'Actives',
                      value: '$_kpiActive',
                      accent: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'En pause',
                      value: '$_kpiPaused',
                      accent: const Color(0xFFFFD166),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'Total',
                      value: '$_kpiTotal',
                      accent: const Color(0xFF7CF5A2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== Recherche + filtres =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Rechercher (nom, raison, rues)…',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Tous'),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _levelFilter = null;
                              _statusFilter = null;
                            });
                          },
                        ),
                        _chipLevel(ZoneLevel.low, 'Faible'),
                        _chipLevel(ZoneLevel.medium, 'Moyen'),
                        _chipLevel(ZoneLevel.high, 'Élevé'),
                        _chipLevel(ZoneLevel.critical, 'Critique'),
                        _chipStatus(ZoneStatus.active, 'Actives'),
                        _chipStatus(ZoneStatus.paused, 'En pause'),
                        _chipStatus(ZoneStatus.archived, 'Archivées'),
                        _sortChip(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== Carte (CustomPainter) =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: _ZonesMapPainter(
                          zones: _zones,
                          me: _me,
                          azimuth: _azimuth,
                          t: _t,
                        ),
                        size: Size.infinite,
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Column(
                          children: [
                            _MapMiniBtn(
                              icon: Icons.my_location,
                              tooltip: 'Centrer sur moi',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _snack('Centrage (mock)');
                              },
                            ),
                            const SizedBox(height: 8),
                            _MapMiniBtn(
                              icon: Icons.edit_location_alt_outlined,
                              tooltip: 'Éditer périmètre (mock)',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _snack('Mode édition (mock)');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== Liste =====
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 44,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune zone',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modifie tes filtres ou crée une zone.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final z = items[i];
                  return Dismissible(
                    key: ValueKey(z.id),
                    background: _dismissBg(
                      color: Colors.teal,
                      icon: Icons.archive_rounded,
                      label: 'Archiver',
                      left: true,
                    ),
                    secondaryBackground: _dismissBg(
                      color: Colors.redAccent,
                      icon: Icons.delete_forever_rounded,
                      label: 'Supprimer',
                      left: false,
                    ),
                    confirmDismiss: (dir) async {
                      if (dir == DismissDirection.startToEnd) {
                        _archive(z);
                      } else {
                        _delete(z);
                      }
                      return true;
                    },
                    child: _ZoneCard(
                      z: z,
                      levelColor: _levelColor(z.level),
                      statusColor: _statusColor(z.status),
                      updatedLabel: _ago(z.lastUpdate),
                      onTap: () => _openDetails(z),
                    ),
                  );
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _createZoneDialog,
      //   icon: const Icon(Icons.add_rounded),
      //   label: const Text('Nouvelle zone'),
      // ),
    );
  }

  // -------- Widgets auxiliaires --------
  Widget _chipLevel(ZoneLevel l, String label) => FilterChip(
    label: Text(label),
    selected: _levelFilter == l,
    selectedColor: _levelColor(l).withOpacity(.12),
    onSelected: (_) => setState(() => _levelFilter = l),
  );

  Widget _chipStatus(ZoneStatus s, String label) => FilterChip(
    label: Text(label),
    selected: _statusFilter == s,
    selectedColor: _statusColor(s).withOpacity(.12),
    onSelected: (_) => setState(() => _statusFilter = s),
  );

  Widget _sortChip() => InputChip(
    label: Text(_sortNewestFirst ? 'Plus récents' : 'Plus anciens'),
    avatar: Icon(
      _sortNewestFirst
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      size: 18,
    ),
    onPressed: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
  );

  Widget _dismissBg({
    required Color color,
    required IconData icon,
    required String label,
    required bool left,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  void _openDetails(RedZone z) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ZoneDetailsSheet(
        z: z,
        levelColor: _levelColor(z.level),
        statusColor: _statusColor(z.status),
        onToggleActive: () => _toggleActive(z),
        onNotifyUnits: () => _notifyUnits(z),
        onEditPolygon: () => _simulateEditPolygon(z),
      ),
    );
  }
}

/* ======================== Widgets ======================== */

class _ZoneCard extends StatelessWidget {
  final RedZone z;
  final Color levelColor;
  final Color statusColor;
  final String updatedLabel;
  final VoidCallback onTap;

  const _ZoneCard({
    required this.z,
    required this.levelColor,
    required this.statusColor,
    required this.updatedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = z.status == ZoneStatus.archived;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: levelColor.withOpacity(.28), width: 1.1),
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              spreadRadius: -10,
              offset: const Offset(0, 14),
              color: levelColor.withOpacity(.12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // pastille niveau
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: levelColor.withOpacity(.35)),
                ),
                child: Icon(Icons.warning_amber_rounded, color: levelColor),
              ),
              const SizedBox(width: 12),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            z.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: muted
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: statusColor.withOpacity(.35),
                            ),
                          ),
                          child: Text(
                            z.status == ZoneStatus.active
                                ? 'Active'
                                : z.status == ZoneStatus.paused
                                ? 'En pause'
                                : 'Archivée',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Raison
                    Text(
                      z.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 8),
                    // Meta
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: levelColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MAJ $updatedLabel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        if (z.affectedStreets.isNotEmpty)
                          Flexible(
                            child: Text(
                              z.affectedStreets.take(2).join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneDetailsSheet extends StatelessWidget {
  final RedZone z;
  final Color levelColor;
  final Color statusColor;
  final VoidCallback onToggleActive;
  final VoidCallback onNotifyUnits;
  final VoidCallback onEditPolygon;

  const _ZoneDetailsSheet({
    required this.z,
    required this.levelColor,
    required this.statusColor,
    required this.onToggleActive,
    required this.onNotifyUnits,
    required this.onEditPolygon,
  });

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Colors.grey.shade600);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: levelColor.withOpacity(.35)),
                  ),
                  child: Text(
                    'Niveau ${_levelLabel(z.level)}',
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(.35)),
                  ),
                  child: Text(
                    z.status == ZoneStatus.active
                        ? 'Active'
                        : z.status == ZoneStatus.paused
                        ? 'En pause'
                        : 'Archivée',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              z.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Créée ${_ago(z.createdAt)} • MAJ ${_ago(z.lastUpdate)}',
                  style: muted,
                ),
              ],
            ),
            const SizedBox(height: 10),

            const Text('Raison', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(z.reason, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 10),

            if (z.affectedStreets.isNotEmpty) ...[
              const Text(
                'Rues impactées',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: z.affectedStreets
                    .take(8)
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],

            const Text(
              'Périmètre (aperçu)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: _ZonePreviewPainter(z.polygon),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditPolygon,
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Éditer périmètre'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNotifyUnits,
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Notifier unités'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onToggleActive,
              icon: Icon(
                z.status == ZoneStatus.active
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              label: Text(
                z.status == ZoneStatus.active ? 'Mettre en pause' : 'Activer',
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'à l’instant';
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays} j';
  }

  String _levelLabel(ZoneLevel l) {
    switch (l) {
      case ZoneLevel.low:
        return 'faible';
      case ZoneLevel.medium:
        return 'moyen';
      case ZoneLevel.high:
        return 'élevé';
      case ZoneLevel.critical:
        return 'critique';
    }
  }
}

/* ======================== Painters ======================== */

class _ZonesMapPainter extends CustomPainter {
  final List<RedZone> zones;
  final Offset me;
  final double azimuth;
  final double t;

  _ZonesMapPainter({
    required this.zones,
    required this.me,
    required this.azimuth,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // fond
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    _drawGrid(canvas, size);
    _drawRoutes(canvas, size);

    // zones
    for (final z in zones) {
      _drawZone(canvas, size, z);
    }

    // moi (agent)
    _drawMe(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final step = 36.0;
    final p = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _drawRoutes(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black.withOpacity(.06)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .1, size.height * .8)
      ..quadraticBezierTo(
        size.width * .3,
        size.height * .6,
        size.width * .5,
        size.height * .7,
      )
      ..quadraticBezierTo(
        size.width * .7,
        size.height * .8,
        size.width * .9,
        size.height * .4,
      );
    canvas.drawPath(path, p);
  }

  void _drawZone(Canvas canvas, Size size, RedZone z) {
    final tr = (Offset o) => Offset(o.dx * size.width, o.dy * size.height);
    final path = Path()..moveTo(tr(z.polygon.first).dx, tr(z.polygon.first).dy);
    for (int i = 1; i < z.polygon.length; i++) {
      path.lineTo(tr(z.polygon[i]).dx, tr(z.polygon[i]).dy);
    }
    path.close();

    final lvlColor = _level(z.level);
    final fill = Paint()..color = lvlColor.withOpacity(.12);
    final stroke = Paint()
      ..color = lvlColor.withOpacity(.45)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // pulsation légère si active
    if (z.status == ZoneStatus.active) {
      final r = (sin(2 * pi * (t % 1)) + 1) / 2; // 0..1
      final glow = Paint()
        ..color = lvlColor.withOpacity(.10 + .10 * r)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(path, glow);
    }

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    // label
    final centroid = _centroid(z.polygon);
    final pos = Offset(centroid.dx * size.width, centroid.dy * size.height);
    _drawLabel(canvas, pos, z.name, lvlColor);
  }

  Offset _centroid(List<Offset> pts) {
    double x = 0, y = 0;
    for (final p in pts) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / pts.length, y / pts.length);
  }

  Color _level(ZoneLevel l) {
    switch (l) {
      case ZoneLevel.low:
        return Colors.teal;
      case ZoneLevel.medium:
        return Colors.amber.shade700;
      case ZoneLevel.high:
        return Colors.redAccent;
      case ZoneLevel.critical:
        return const Color(0xFFD93025);
    }
  }

  void _drawMe(Canvas canvas, Size size) {
    final pos = Offset(me.dx * size.width, me.dy * size.height);
    final dir = Offset(cos(azimuth), sin(azimuth));
    final arrowEnd = pos + dir * 26;

    final pDir = Paint()
      ..color = Colors.blueAccent.withOpacity(.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos, arrowEnd, pDir);

    final halo = Paint()..color = Colors.blueAccent.withOpacity(.18);
    canvas.drawCircle(pos, 14, halo);
    final mePaint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(pos, 7, mePaint);

    _drawLabel(canvas, pos + const Offset(10, -18), "Vous", Colors.blueAccent);
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 200);
    final bg = Paint()..color = Colors.white.withOpacity(.9);
    final rect = Rect.fromLTWH(
      pos.dx - 6,
      pos.dy - 2,
      tp.width + 12,
      tp.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      bg,
    );
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _ZonesMapPainter old) =>
      old.t != t ||
      old.zones != zones ||
      old.me != me ||
      old.azimuth != azimuth;
}

class _ZonePreviewPainter extends CustomPainter {
  final List<Offset> polygon;
  _ZonePreviewPainter(this.polygon);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final tr = (Offset o) => Offset(o.dx * size.width, o.dy * size.height);

    final path = Path()..moveTo(tr(polygon.first).dx, tr(polygon.first).dy);
    for (int i = 1; i < polygon.length; i++) {
      path.lineTo(tr(polygon[i]).dx, tr(polygon[i]).dy);
    }
    path.close();

    final stroke = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..color = Colors.redAccent.withOpacity(.12);

    // grille sobre
    final step = 30.0;
    final grid = Paint()..color = Colors.black12;
    for (double x = 0; x <= size.width; x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y <= size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ZonePreviewPainter old) =>
      old.polygon != polygon;
}

/* ======================== UI utilitaires ======================== */

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(.28), width: 1.1),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            spreadRadius: -12,
            offset: const Offset(0, 12),
            color: accent.withOpacity(.18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .08,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: const Alignment(0.2, -0.6),
                    radius: 1.0,
                    colors: [accent, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.45)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: -6,
                color: Colors.cyanAccent.withOpacity(0.18),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _MapMiniBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _MapMiniBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: -8,
                color: Colors.black12,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black87),
        ),
      ),
    );
  }
}

/* ======================== Orbe IA (header) ======================== */

class _AiGlowPainter extends CustomPainter {
  final double intensity;
  _AiGlowPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .75, size.height * .2);
    final r1 = size.shortestSide * (0.55 + 0.15 * intensity);
    final r2 = r1 * 0.55;
    final r3 = r1 * 0.25;

    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.cyanAccent.withOpacity(0.28 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r1));
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.22 + 0.12 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r2));
    final p3 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.18 + 0.1 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r3));

    canvas.drawCircle(center, r1, p1);
    canvas.drawCircle(center, r2, p2);
    canvas.drawCircle(center, r3, p3);
  }

  @override
  bool shouldRepaint(covariant _AiGlowPainter old) =>
      old.intensity != intensity;
}
