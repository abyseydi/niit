import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niit/ui/widgets/app_bar.dart';

/// ============================ Modèles ============================

enum ReportType { incident, patrouille, quotidien, controle, autre }

enum ReportStatus { brouillon, soumis, valide, rejete }

enum ReportPriority { basse, normale, haute, critique }

class Report {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime lastEdit;
  ReportType type;
  ReportStatus status;
  ReportPriority priority;
  String auteur;
  String? interventionId;
  String? plate;
  List<String> tags;
  String body;
  String? aiSummary;
  int attachments;

  Report({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastEdit,
    required this.type,
    required this.status,
    required this.priority,
    required this.auteur,
    this.interventionId,
    this.plate,
    this.tags = const [],
    this.body = '',
    this.aiSummary,
    this.attachments = 0,
  });
}

/// ============================ Page ============================

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with TickerProviderStateMixin {
  // Mock de départ
  final List<Report> _all = [
    Report(
      id: 'r1',
      title: 'Infraction vitesse – DK-4821-AB',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      lastEdit: DateTime.now().subtract(const Duration(minutes: 5)),
      type: ReportType.incident,
      status: ReportStatus.brouillon,
      priority: ReportPriority.haute,
      auteur: 'Adj. NIANG',
      plate: 'DK-4821-AB',
      interventionId: 'i1',
      tags: const ['vitesse', 'caméra', 'zone rouge'],
      body: 'Véhicule détecté à 85km/h dans une zone 50 près de Colobane.',
      attachments: 2,
    ),
    Report(
      id: 'r2',
      title: 'Patrouille nuit – Secteur Point E',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      lastEdit: DateTime.now().subtract(const Duration(hours: 4, minutes: 10)),
      type: ReportType.patrouille,
      status: ReportStatus.soumis,
      priority: ReportPriority.normale,
      auteur: 'Brig. DIOP',
      body: 'RAS principal. Regroupement dissipé pacifiquement à 01:40.',
      attachments: 1,
    ),
    Report(
      id: 'r3',
      title: 'Rapport quotidien – Unité U-13',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      lastEdit: DateTime.now().subtract(
        const Duration(days: 1, hours: 1, minutes: 10),
      ),
      type: ReportType.quotidien,
      status: ReportStatus.valide,
      priority: ReportPriority.basse,
      auteur: 'Lt. SOW',
      body: 'Activité régulière. 3 contrôles, 0 garde à vue.',
      attachments: 0,
    ),
  ];

  // UI / filtres
  final _searchCtrl = TextEditingController();
  ReportStatus? _statusFilter;
  ReportType? _typeFilter;
  ReportPriority? _prioFilter;
  bool _sortNewestFirst = true;

  // Glow header
  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // =============== Helpers ===============
  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'à l’instant';
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays} j';
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.brouillon:
        return Colors.blueAccent;
      case ReportStatus.soumis:
        return Colors.amber.shade800;
      case ReportStatus.valide:
        return Colors.green;
      case ReportStatus.rejete:
        return const Color(0xFFD93025);
    }
  }

  String _statusLabel(ReportStatus s) {
    switch (s) {
      case ReportStatus.brouillon:
        return 'Brouillon';
      case ReportStatus.soumis:
        return 'Soumis';
      case ReportStatus.valide:
        return 'Validé';
      case ReportStatus.rejete:
        return 'Rejeté';
    }
  }

  IconData _typeIcon(ReportType t) {
    switch (t) {
      case ReportType.incident:
        return Icons.report_gmailerrorred_outlined;
      case ReportType.patrouille:
        return Icons.shield_outlined;
      case ReportType.quotidien:
        return Icons.today_outlined;
      case ReportType.controle:
        return Icons.verified_user_outlined;
      case ReportType.autre:
        return Icons.description_outlined;
    }
  }

  Color _prioDot(ReportPriority p) {
    switch (p) {
      case ReportPriority.basse:
        return Colors.teal;
      case ReportPriority.normale:
        return Colors.amber.shade700;
      case ReportPriority.haute:
        return Colors.redAccent;
      case ReportPriority.critique:
        return const Color(0xFFD93025);
    }
  }

  // Filtres
  List<Report> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _all.where((r) {
      if (_statusFilter != null && r.status != _statusFilter) return false;
      if (_typeFilter != null && r.type != _typeFilter) return false;
      if (_prioFilter != null && r.priority != _prioFilter) return false;
      if (q.isEmpty) return true;
      final hay = [
        r.title,
        r.auteur,
        r.body,
        r.aiSummary ?? '',
        r.plate ?? '',
        r.interventionId ?? '',
        ...r.tags,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();

    list.sort(
      (a, b) => _sortNewestFirst
          ? b.lastEdit.compareTo(a.lastEdit)
          : a.lastEdit.compareTo(b.lastEdit),
    );
    return list;
  }

  // =============== Actions ===============
  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _createReport() {
    final title = TextEditingController();
    ReportType type = ReportType.incident;
    ReportPriority prio = ReportPriority.normale;
    final plate = TextEditingController();
    final body = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau rapport'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReportType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ReportType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) => type = v ?? type,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReportPriority>(
                value: prio,
                decoration: const InputDecoration(labelText: 'Priorité'),
                items: ReportPriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => prio = v ?? prio,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: plate,
                decoration: const InputDecoration(
                  labelText: 'Plaque (optionnel)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: body,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Contenu'),
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
              if (title.text.trim().isEmpty) return;
              setState(() {
                _all.insert(
                  0,
                  Report(
                    id: 'r${DateTime.now().millisecondsSinceEpoch}',
                    title: title.text.trim(),
                    createdAt: DateTime.now(),
                    lastEdit: DateTime.now(),
                    type: type,
                    status: ReportStatus.brouillon,
                    priority: prio,
                    auteur: 'Moi',
                    plate: plate.text.trim().isEmpty ? null : plate.text.trim(),
                    body: body.text.trim(),
                    tags: const [],
                    attachments: 0,
                  ),
                );
              });
              Navigator.pop(context);
              _snack('Rapport créé');
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _submit(Report r) {
    setState(() {
      r.status = ReportStatus.soumis;
      r.lastEdit = DateTime.now();
    });
    _snack('Rapport soumis');
  }

  void _approve(Report r) {
    setState(() {
      r.status = ReportStatus.valide;
      r.lastEdit = DateTime.now();
    });
    _snack('Rapport validé ✅');
  }

  void _reject(Report r) {
    setState(() {
      r.status = ReportStatus.rejete;
      r.lastEdit = DateTime.now();
    });
    _snack('Rapport rejeté');
  }

  void _delete(Report r) {
    setState(() => _all.removeWhere((x) => x.id == r.id));
    _snack('Rapport supprimé');
  }

  void _exportPdf(Report r) {
    _snack('Export PDF simulé (mock local)');
  }

  void _genAiSummary(Report r) {
    // Résumé IA mock — heuristique très simple pour la démo
    final base = r.body.isNotEmpty ? r.body : r.title;
    final trimmed = base.replaceAll(RegExp(r'\s+'), ' ').trim();
    final take = min(180, trimmed.length);
    final key = r.tags.isNotEmpty
        ? ' / Tags: ${r.tags.take(3).join(', ')}'
        : '';
    setState(() {
      r.aiSummary =
          '${trimmed.substring(0, take)}${trimmed.length > take ? '…' : ''}$key';
      r.lastEdit = DateTime.now();
    });
    _snack('Résumé IA généré');
  }

  // =============== Build ===============
  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    final kpiDraft = _all
        .where((e) => e.status == ReportStatus.brouillon)
        .length;
    final kpiPending = _all
        .where((e) => e.status == ReportStatus.soumis)
        .length;
    final kpiValid = _all.where((e) => e.status == ReportStatus.valide).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: CustomAppBar(),
      body: CustomScrollView(
        slivers: [
          // -------- Header IA --------
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
                                  'Rapports',
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
                                '$kpiDraft brouillon(s) • $kpiPending en attente • $kpiValid validé(s)',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HeaderAction(
                          icon: Icons.add_circle_outline,
                          tooltip: 'Nouveau rapport',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _createReport();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------- KPIs --------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: 'Brouillons',
                      value: '$kpiDraft',
                      accent: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'Soumis',
                      value: '$kpiPending',
                      accent: const Color(0xFFFFD166),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'Validés',
                      value: '$kpiValid',
                      accent: const Color(0xFF7CF5A2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------- Recherche + filtres --------
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
                      hintText: 'Rechercher (titre, auteur, plaque, tag)…',
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
                              _statusFilter = null;
                              _typeFilter = null;
                              _prioFilter = null;
                            });
                          },
                        ),
                        _chipStatus(ReportStatus.brouillon, 'Brouillons'),
                        _chipStatus(ReportStatus.soumis, 'Soumis'),
                        _chipStatus(ReportStatus.valide, 'Validés'),
                        _chipStatus(ReportStatus.rejete, 'Rejetés'),
                        _chipType(ReportType.incident, 'Incident'),
                        _chipType(ReportType.patrouille, 'Patrouille'),
                        _chipType(ReportType.quotidien, 'Quotidien'),
                        _chipType(ReportType.controle, 'Contrôle'),
                        _chipPrio(ReportPriority.critique, 'Critique'),
                        _chipPrio(ReportPriority.haute, 'Haute'),
                        _sortChip(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------- Liste --------
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
                      'Aucun rapport',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modifie tes filtres ou crée un rapport.',
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
                  final r = items[i];
                  return Dismissible(
                    key: ValueKey(r.id),
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
                      if (dir == DismissDirection.endToStart) {
                        _delete(r);
                      } else {
                        _snack('Archivé (mock)');
                      }
                      return true;
                    },
                    child: _ReportCard(
                      r: r,
                      typeIcon: _typeIcon(r.type),
                      statusColor: _statusColor(r.status),
                      prioDot: _prioDot(r.priority),
                      onTap: () => _openDetails(r),
                    ),
                  );
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _createReport,
      //   icon: const Icon(Icons.add_rounded),
      //   label: const Text('Nouveau'),
      // ),
    );
  }

  // -------- Widgets auxiliaires --------
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

  Widget _chipStatus(ReportStatus s, String label) => FilterChip(
    label: Text(label),
    selected: _statusFilter == s,
    selectedColor: _statusColor(s).withOpacity(.12),
    onSelected: (_) => setState(() => _statusFilter = s),
  );

  Widget _chipType(ReportType t, String label) => FilterChip(
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_typeIcon(t), size: 16),
        const SizedBox(width: 6),
        Text(label),
      ],
    ),
    selected: _typeFilter == t,
    onSelected: (_) => setState(() => _typeFilter = t),
  );

  Widget _chipPrio(ReportPriority p, String label) => FilterChip(
    label: Text(label),
    selected: _prioFilter == p,
    selectedColor: _prioDot(p).withOpacity(.12),
    onSelected: (_) => setState(() => _prioFilter = p),
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

  void _openDetails(Report r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ReportDetailsSheet(
        r: r,
        timeAgo: _ago(r.lastEdit),
        statusColor: _statusColor(r.status),
        statusLabel: _statusLabel(r.status),
        prioDot: _prioDot(r.priority),
        onGenerateAi: () => _genAiSummary(r),
        onSubmit: () => _submit(r),
        onApprove: () => _approve(r),
        onReject: () => _reject(r),
        onExport: () => _exportPdf(r),
      ),
    );
  }
}

/// ============================ Widgets ============================

class _ReportCard extends StatelessWidget {
  final Report r;
  final IconData typeIcon;
  final Color statusColor;
  final Color prioDot;
  final VoidCallback onTap;

  const _ReportCard({
    required this.r,
    required this.typeIcon,
    required this.statusColor,
    required this.prioDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = r.status == ReportStatus.rejete;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(.28), width: 1.1),
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              spreadRadius: -10,
              offset: const Offset(0, 14),
              color: statusColor.withOpacity(.12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône type
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(.35)),
                ),
                child: Icon(typeIcon, color: statusColor),
              ),
              const SizedBox(width: 12),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
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
                            r.status == ReportStatus.brouillon
                                ? 'Brouillon'
                                : r.status == ReportStatus.soumis
                                ? 'Soumis'
                                : r.status == ReportStatus.valide
                                ? 'Validé'
                                : 'Rejeté',
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
                    Wrap(
                      spacing: 8,
                      runSpacing: -6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              r.auteur,
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                        if (r.plate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_police_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                r.plate!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        if (r.attachments > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.attachment,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text('${r.attachments}'),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: prioDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Modifié ${_ago(r.lastEdit)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        if (r.tags.isNotEmpty)
                          Flexible(
                            child: Text(
                              r.tags.take(3).map((e) => '#$e').join('  '),
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

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'à l’instant';
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays} j';
  }
}

class _ReportDetailsSheet extends StatelessWidget {
  final Report r;
  final String timeAgo;
  final Color statusColor;
  final String statusLabel;
  final Color prioDot;
  final VoidCallback onGenerateAi;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onExport;

  const _ReportDetailsSheet({
    required this.r,
    required this.timeAgo,
    required this.statusColor,
    required this.statusLabel,
    required this.prioDot,
    required this.onGenerateAi,
    required this.onSubmit,
    required this.onApprove,
    required this.onReject,
    required this.onExport,
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
                    color: statusColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(.35)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: prioDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Priorité ${r.priority.name}', style: muted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              r.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(r.auteur),
                const Spacer(),
                const Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text('Modifié $timeAgo', style: muted),
              ],
            ),
            const SizedBox(height: 6),
            if (r.plate != null || r.interventionId != null)
              Row(
                children: [
                  if (r.plate != null) ...[
                    const Icon(
                      Icons.local_police_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text('Plaque : ${r.plate}'),
                    const SizedBox(width: 14),
                  ],
                  if (r.interventionId != null) ...[
                    const Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text('Interv. ${r.interventionId}'),
                  ],
                ],
              ),
            if (r.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: r.tags
                    .take(6)
                    .map((t) => Chip(label: Text('#$t')))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),

            // Corps & résumé IA
            const Text(
              'Contenu',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              r.body.isEmpty ? '— (vide) —' : r.body,
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Résumé IA',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                if (r.aiSummary == null)
                  OutlinedButton.icon(
                    onPressed: onGenerateAi,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Générer'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                r.aiSummary ?? '— Pas encore généré —',
                style: TextStyle(
                  color: r.aiSummary == null
                      ? Colors.grey.shade600
                      : Colors.black87,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExport,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exporter PDF'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Soumettre'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Valider'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Rejeter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// KPI “verre + néon”
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

/// Bouton header (glow subtil)
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

/// Orbe IA (header)
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
