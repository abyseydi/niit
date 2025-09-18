import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niit/ui/widgets/app_bar.dart';

/// =============================================================
///  MODELES
/// =============================================================
enum InterventionStatus { newi, assigned, inProgress, resolved, archived }

enum InterventionPriority { low, normal, high, critical }

enum InterventionType { offense, patrol, accident, assistance, other }

class Intervention {
  final String id;
  final String title;
  final String location;
  final DateTime createdAt;
  final InterventionType type;
  InterventionPriority priority;
  InterventionStatus status;
  late final String? assignedTo; // agent ou équipe
  final String? plate; // si lié à une plaque
  final String? notes;

  Intervention({
    required this.id,
    required this.title,
    required this.location,
    required this.createdAt,
    required this.type,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.plate,
    this.notes,
  });
}

/// =============================================================
///  PAGE
/// =============================================================
class InterventionsPage extends StatefulWidget {
  const InterventionsPage({super.key});
  @override
  State<InterventionsPage> createState() => _InterventionsPageState();
}

class _InterventionsPageState extends State<InterventionsPage>
    with TickerProviderStateMixin {
  // ---------------- Mock de base ----------------
  final List<Intervention> _all = [
    Intervention(
      id: "i1",
      title: "Plaque suspecte",
      location: "Avenue Blaise Diagne",
      createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
      type: InterventionType.offense,
      priority: InterventionPriority.critical,
      status: InterventionStatus.newi,
      plate: "DK-4821-AB",
      notes: "Signalement caméra IA — véhicule en zone rouge.",
      assignedTo: null,
    ),
    Intervention(
      id: "i2",
      title: "Assistance routière",
      location: "Point E",
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      type: InterventionType.assistance,
      priority: InterventionPriority.normal,
      status: InterventionStatus.assigned,
      assignedTo: "Unité U-13",
    ),
    Intervention(
      id: "i3",
      title: "Accident matériel",
      location: "Corniche Ouest",
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      type: InterventionType.accident,
      priority: InterventionPriority.high,
      status: InterventionStatus.inProgress,
      assignedTo: "Patrouille P-7",
      notes: "Deux véhicules impliqués, pas de blessés.",
    ),
    Intervention(
      id: "i4",
      title: "Patrouille de routine",
      location: "HLM Grand Yoff",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      type: InterventionType.patrol,
      priority: InterventionPriority.low,
      status: InterventionStatus.resolved,
      assignedTo: "Patrouille P-2",
      notes: "RAS",
    ),
  ];

  // ---------------- Etat UI ----------------
  final _searchCtrl = TextEditingController();
  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  InterventionStatus? _statusFilter;
  InterventionPriority? _prioFilter;
  InterventionType? _typeFilter;
  String _query = '';
  bool _sortNewestFirst = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ---------------- Helpers visuels ----------------
  Color _statusColor(InterventionStatus s) {
    switch (s) {
      case InterventionStatus.newi:
        return Colors.blueAccent;
      case InterventionStatus.assigned:
        return Colors.deepPurpleAccent;
      case InterventionStatus.inProgress:
        return Colors.orangeAccent;
      case InterventionStatus.resolved:
        return Colors.green;
      case InterventionStatus.archived:
        return Colors.grey;
    }
  }

  String _statusLabel(InterventionStatus s) {
    switch (s) {
      case InterventionStatus.newi:
        return "Nouveau";
      case InterventionStatus.assigned:
        return "Assigné";
      case InterventionStatus.inProgress:
        return "En cours";
      case InterventionStatus.resolved:
        return "Clôturé";
      case InterventionStatus.archived:
        return "Archivé";
    }
  }

  IconData _typeIcon(InterventionType t) {
    switch (t) {
      case InterventionType.offense:
        return Icons.gavel_rounded;
      case InterventionType.patrol:
        return Icons.shield_rounded;
      case InterventionType.accident:
        return Icons.car_crash_rounded;
      case InterventionType.assistance:
        return Icons.volunteer_activism_rounded;
      case InterventionType.other:
        return Icons.pending_actions_rounded;
    }
  }

  Color _prioDot(InterventionPriority p) {
    switch (p) {
      case InterventionPriority.low:
        return Colors.teal;
      case InterventionPriority.normal:
        return Colors.amber.shade700;
      case InterventionPriority.high:
        return Colors.redAccent;
      case InterventionPriority.critical:
        return const Color(0xFFD93025);
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return "à l’instant";
    if (d.inMinutes < 60) return "il y a ${d.inMinutes} min";
    if (d.inHours < 24) return "il y a ${d.inHours} h";
    if (d.inDays == 1) return "hier";
    return "il y a ${d.inDays} j";
  }

  // ---------------- Filtrage ----------------
  List<Intervention> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = _all.where((i) {
      if (_statusFilter != null && i.status != _statusFilter) return false;
      if (_prioFilter != null && i.priority != _prioFilter) return false;
      if (_typeFilter != null && i.type != _typeFilter) return false;
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q) ||
          (i.plate ?? "").toLowerCase().contains(q) ||
          (i.notes ?? "").toLowerCase().contains(q);
    }).toList();

    list.sort(
      (a, b) => _sortNewestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
    return list;
  }

  // ---------------- Actions ----------------
  void _assign(Intervention i) {
    setState(() {
      i.status = InterventionStatus.assigned;
      i.assignedTo ??= "Patrouille P-1";
    });
    _snack("Intervention assignée à ${i.assignedTo}");
  }

  void _start(Intervention i) {
    setState(() => i.status = InterventionStatus.inProgress);
    _snack("Intervention démarrée");
  }

  void _resolve(Intervention i) {
    setState(() => i.status = InterventionStatus.resolved);
    _snack("Intervention clôturée ✅");
  }

  void _archive(Intervention i) {
    setState(() => i.status = InterventionStatus.archived);
    _snack("Intervention archivée");
  }

  void _delete(Intervention i) {
    setState(() => _all.removeWhere((x) => x.id == i.id));
    _snack("Intervention supprimée");
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    setState(() {
      _all.insert(
        0,
        Intervention(
          id: "i${DateTime.now().millisecondsSinceEpoch}",
          title: "Brief QG",
          location: "Salle Ops",
          createdAt: DateTime.now(),
          type: InterventionType.other,
          priority: InterventionPriority.low,
          status: InterventionStatus.newi,
        ),
      );
    });
  }

  void _createInterventionDialog() {
    final titleCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    InterventionType type = InterventionType.other;
    InterventionPriority prio = InterventionPriority.normal;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nouvelle intervention"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Titre",
                  hintText: "Ex: Rassemblement non autorisé",
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(
                  labelText: "Lieu",
                  hintText: "Adresse, repère...",
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<InterventionType>(
                value: type,
                decoration: const InputDecoration(labelText: "Type"),
                items: InterventionType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) => type = v ?? type,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<InterventionPriority>(
                value: prio,
                decoration: const InputDecoration(labelText: "Priorité"),
                items: InterventionPriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => prio = v ?? prio,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty || locCtrl.text.trim().isEmpty)
                return;
              setState(() {
                _all.insert(
                  0,
                  Intervention(
                    id: "i${DateTime.now().millisecondsSinceEpoch}",
                    title: titleCtrl.text.trim(),
                    location: locCtrl.text.trim(),
                    createdAt: DateTime.now(),
                    type: type,
                    priority: prio,
                    status: InterventionStatus.newi,
                  ),
                );
              });
              Navigator.pop(context);
              _snack("Intervention créée");
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final unread = items
        .where((e) => e.status == InterventionStatus.newi)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: CustomAppBar(),
      body: CustomScrollView(
        slivers: [
          // ===== HEADER IA =====
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
                          child: Image.asset("assets/img/police_logo.png"),
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
                                  "Interventions",
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
                                "$unread nouveau(x) • ${items.length} au total",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HeaderAction(
                          icon: Icons.add_circle_outline,
                          tooltip: "Créer",
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _createInterventionDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== KPIs (verre + néon) =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: "Nouveaux",
                      value: _all
                          .where((e) => e.status == InterventionStatus.newi)
                          .length
                          .toString(),
                      accent: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: "En cours",
                      value: _all
                          .where(
                            (e) => e.status == InterventionStatus.inProgress,
                          )
                          .length
                          .toString(),
                      accent: const Color(0xFFFFD166),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: "Clôturés",
                      value: _all
                          .where((e) => e.status == InterventionStatus.resolved)
                          .length
                          .toString(),
                      accent: const Color(0xFF7CF5A2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== Recherche + Filtres =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Rechercher (titre, lieu, plaque)…',
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
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
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
                        _chipAll(
                          "Tous",
                          onTap: () {
                            setState(() {
                              _statusFilter = null;
                              _prioFilter = null;
                              _typeFilter = null;
                            });
                          },
                        ),
                        _chipStatus(InterventionStatus.newi, "Nouveau"),
                        _chipStatus(InterventionStatus.assigned, "Assigné"),
                        _chipStatus(InterventionStatus.inProgress, "En cours"),
                        _chipStatus(InterventionStatus.resolved, "Clôturé"),
                        _chipPrio(InterventionPriority.critical, "Critique"),
                        _chipPrio(InterventionPriority.high, "Haut"),
                        _chipPrio(InterventionPriority.normal, "Normal"),
                        _chipType(InterventionType.offense, "Infraction"),
                        _chipType(InterventionType.accident, "Accident"),
                        _chipType(InterventionType.assistance, "Assistance"),
                        _sortChip(),
                      ],
                    ),
                  ),
                ],
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
                      'Aucune intervention',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modifie tes filtres ou crée une intervention.',
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
                  final it = items[i];
                  return Dismissible(
                    key: ValueKey(it.id),
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
                        _archive(it);
                      } else {
                        _delete(it);
                      }
                      return true;
                    },
                    child: _InterventionCard(
                      i: it,
                      typeIcon: _typeIcon(it.type),
                      statusColor: _statusColor(it.status),
                      prioDot: _prioDot(it.priority),
                      timeLabel: _timeAgo(it.createdAt),
                      onTap: () => _openDetails(it),
                    ),
                  );
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ===== FAB créer =====
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _createInterventionDialog,
      //   icon: const Icon(Icons.add_rounded),
      //   label: const Text("Nouvelle"),
      // ),
    );
  }

  // ---------------- Widgets auxiliaires ----------------
  Widget _chipAll(String label, {required VoidCallback onTap}) => ActionChip(
    label: Text(label),
    onPressed: () {
      HapticFeedback.selectionClick();
      onTap();
    },
  );

  Widget _chipStatus(InterventionStatus s, String label) => FilterChip(
    label: Text(label),
    selected: _statusFilter == s,
    selectedColor: _statusColor(s).withOpacity(.12),
    onSelected: (_) => setState(() => _statusFilter = s),
  );

  Widget _chipPrio(InterventionPriority p, String label) => FilterChip(
    label: Text(label),
    selected: _prioFilter == p,
    selectedColor: _prioDot(p).withOpacity(.12),
    onSelected: (_) => setState(() => _prioFilter = p),
  );

  Widget _chipType(InterventionType t, String label) => FilterChip(
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

  void _openDetails(Intervention i) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DetailsSheet(
        data: i,
        timeAgo: _timeAgo(i.createdAt),
        statusColor: _statusColor(i.status),
        statusLabel: _statusLabel(i.status),
        prioDot: _prioDot(i.priority),
        onAssign: () => _assign(i),
        onStart: () => _start(i),
        onResolve: () => _resolve(i),
      ),
    );
  }
}

/// =============================================================
///  WIDGETS
/// =============================================================

class _InterventionCard extends StatelessWidget {
  final Intervention i;
  final IconData typeIcon;
  final Color statusColor;
  final Color prioDot;
  final String timeLabel;
  final VoidCallback onTap;

  const _InterventionCard({
    required this.i,
    required this.typeIcon,
    required this.statusColor,
    required this.prioDot,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = i.status == InterventionStatus.archived;
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
                    // Titre + actions rapides
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            i.title,
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
                            i.status == InterventionStatus.newi
                                ? "Nouveau"
                                : i.status == InterventionStatus.assigned
                                ? "Assigné"
                                : i.status == InterventionStatus.inProgress
                                ? "En cours"
                                : i.status == InterventionStatus.resolved
                                ? "Clôturé"
                                : "Archivé",
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
                    // Lieu + plaque éventuelle
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            i.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ),
                        if (i.plate != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.local_police_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            i.plate!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Meta
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
                          timeLabel,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        if (i.assignedTo != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.groups_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                i.assignedTo!,
                                style: TextStyle(color: Colors.grey.shade800),
                              ),
                            ],
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
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

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

/// Bottom sheet détails intervention (timeline + actions)
class _DetailsSheet extends StatelessWidget {
  final Intervention data;
  final String timeAgo;
  final Color statusColor;
  final String statusLabel;
  final Color prioDot;
  final VoidCallback onAssign;
  final VoidCallback onStart;
  final VoidCallback onResolve;

  const _DetailsSheet({
    required this.data,
    required this.timeAgo,
    required this.statusColor,
    required this.statusLabel,
    required this.prioDot,
    required this.onAssign,
    required this.onStart,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final styleMuted = TextStyle(color: Colors.grey.shade600);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.45,
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
                    Text("Priorité ${data.priority.name}", style: styleMuted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(data.location)),
              ],
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
                Text(timeAgo, style: styleMuted),
                const Spacer(),
                if (data.assignedTo != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(data.assignedTo!, style: styleMuted),
                    ],
                  ),
              ],
            ),
            if (data.plate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.local_police_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text("Plaque liée : ${data.plate}"),
                ],
              ),
            ],
            if (data.notes != null) ...[
              const SizedBox(height: 10),
              Text(data.notes!, style: const TextStyle(height: 1.35)),
            ],
            const SizedBox(height: 16),

            // Timeline simple
            const Text(
              "Chronologie",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _TimelineItem(
              icon: Icons.flag_circle_outlined,
              label: "Création",
              caption: "Signalement initial",
            ),
            if (data.status != InterventionStatus.newi)
              _TimelineItem(
                icon: Icons.assignment_ind_rounded,
                label: "Assignation",
                caption: data.assignedTo ?? "—",
              ),
            if (data.status == InterventionStatus.inProgress ||
                data.status == InterventionStatus.resolved)
              _TimelineItem(
                icon: Icons.play_circle_outline,
                label: "Démarrage",
                caption: "Unité en route",
              ),
            if (data.status == InterventionStatus.resolved)
              _TimelineItem(
                icon: Icons.verified_outlined,
                label: "Clôture",
                caption: "Intervention terminée",
              ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(Icons.assignment_ind_rounded),
                    label: const Text("Assigner"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text("Démarrer"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onResolve,
              icon: const Icon(Icons.verified_outlined),
              label: const Text("Clôturer l’intervention"),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(caption, style: TextStyle(color: Colors.grey.shade700)),
        ),
      ],
    );
  }
}

/// Orbe IA (glow radial animé)
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
