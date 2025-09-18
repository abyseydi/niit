import 'package:flutter/material.dart';
import 'package:niit/ui/screens/settings.dart';
import 'package:niit/ui/widgets/app_bar.dart';

/// On suppose que PoliceBrand est déjà défini (mêmes couleurs/gradients que ta SettingsPage).
class NotificationHome extends StatefulWidget {
  const NotificationHome({super.key});
  @override
  State<NotificationHome> createState() => _NotificationHomeState();
}

enum NotifType { systeme, securite, maintenance, paiement }

enum NotifPriority { low, normal, high }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotifType type;
  final NotifPriority priority;
  bool isRead;
  bool isArchived;
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.priority,
    this.isRead = false,
    this.isArchived = false,
  });
}

class _NotificationHomeState extends State<NotificationHome> {
  // Mock de départ
  final List<AppNotification> _all = [
    AppNotification(
      id: 'n1',
      title: 'Incident à proximité',
      message: 'Alerte zone rouge à Colobane. Patrouille conseillée.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      type: NotifType.securite,
      priority: NotifPriority.high,
    ),
    AppNotification(
      id: 'n2',
      title: 'Mise à jour système',
      message: 'Correctifs OCR plaques et stabilité.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      type: NotifType.systeme,
      priority: NotifPriority.normal,
      isRead: true,
    ),
    AppNotification(
      id: 'n3',
      title: 'Maintenance planifiée',
      message: 'Interruption 23:00–23:30 (serveur carto).',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      type: NotifType.maintenance,
      priority: NotifPriority.low,
    ),
    AppNotification(
      id: 'n4',
      title: 'Paiement en attente',
      message: 'Régler la facture #2025-0918.',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      type: NotifType.paiement,
      priority: NotifPriority.normal,
    ),
    AppNotification(
      id: 'n5',
      title: 'Nouvelle alerte',
      message: 'Tentative d’accès non autorisé détectée.',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      type: NotifType.securite,
      priority: NotifPriority.high,
    ),
  ];

  // État des filtres
  NotifType? _typeFilter; // null = Tous
  bool _unreadOnly = false;
  String _query = '';
  bool _sortNewestFirst = true;

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Helpers UI
  IconData _iconFor(NotifType t) {
    switch (t) {
      case NotifType.systeme:
        return Icons.system_update_alt_rounded;
      case NotifType.securite:
        return Icons.shield_moon_rounded;
      case NotifType.maintenance:
        return Icons.build_circle_rounded;
      case NotifType.paiement:
        return Icons.receipt_long_rounded;
    }
  }

  Color _colorFor(NotifType t) {
    switch (t) {
      case NotifType.systeme:
        return Colors.blueAccent;
      case NotifType.securite:
        return PoliceBrand.red;
      case NotifType.maintenance:
        return Colors.amber.shade700;
      case NotifType.paiement:
        return Colors.teal;
    }
  }

  Color _priorityDot(NotifPriority p) {
    switch (p) {
      case NotifPriority.low:
        return Colors.green;
      case NotifPriority.normal:
        return Colors.orange;
      case NotifPriority.high:
        return Colors.red;
    }
  }

  String _timeLabel(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'à l’instant';
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays} j';
  }

  List<AppNotification> get _filtered {
    final q = _query.trim().toLowerCase();
    final base = _all.where((n) {
      if (n.isArchived) return false;
      if (_unreadOnly && n.isRead) return false;
      if (_typeFilter != null && n.type != _typeFilter) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          n.message.toLowerCase().contains(q);
    }).toList();

    base.sort(
      (a, b) => _sortNewestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );

    return base;
  }

  // Groupement par jour (Aujourd’hui, Hier, Cette semaine)
  Map<String, List<AppNotification>> _grouped(List<AppNotification> items) {
    final Map<String, List<AppNotification>> m = {};
    final now = DateTime.now();
    for (final n in items) {
      late String key;
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(d).inDays;
      if (diff == 0)
        key = 'Aujourd’hui';
      else if (diff == 1)
        key = 'Hier';
      else
        key = 'Cette semaine';
      (m[key] ??= []).add(n);
    }
    return m;
  }

  // Actions
  void _markAllRead() {
    setState(() {
      for (final n in _all) {
        if (!n.isArchived) n.isRead = true;
      }
    });
  }

  void _toggleRead(AppNotification n) => setState(() => n.isRead = !n.isRead);
  void _archive(AppNotification n) => setState(() => n.isArchived = true);
  void _delete(AppNotification n) =>
      setState(() => _all.removeWhere((x) => x.id == n.id));

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    setState(() {
      _all.insert(
        0,
        AppNotification(
          id: 'n${DateTime.now().millisecondsSinceEpoch}',
          title: 'Brief QG',
          message: 'Réunion flash 16:30 – Salle Ops.',
          createdAt: DateTime.now(),
          type: NotifType.systeme,
          priority: NotifPriority.low,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
    );
    final items = _filtered;
    final groups = _grouped(items);

    return Scaffold(
      backgroundColor: PoliceBrand.light,
      appBar: CustomAppBar(),
      body: CustomScrollView(
        slivers: [
          // ====== HEADER ======
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
                          "Notifications",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${items.where((e) => !e.isRead).length} non lues • ${items.length} au total",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
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

          // ====== BARRE OUTILS (recherche + filtres) ======
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  // Barre de recherche
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Rechercher…',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: PoliceBrand.radiusSm,
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

                  // Filtres inspirés Settings (chips + “Non lus” + tri)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tous'),
                          selected: _typeFilter == null,
                          onSelected: (_) => setState(() => _typeFilter = null),
                        ),
                        _typeChip(NotifType.securite, 'Sécurité'),
                        _typeChip(NotifType.systeme, 'Système'),
                        _typeChip(NotifType.maintenance, 'Maintenance'),
                        _typeChip(NotifType.paiement, 'Paiements'),
                        FilterChip(
                          label: const Text('Non lus'),
                          selected: _unreadOnly,
                          onSelected: (v) => setState(() => _unreadOnly = v),
                        ),
                        InputChip(
                          label: Text(
                            _sortNewestFirst ? 'Plus récents' : 'Plus anciens',
                          ),
                          avatar: Icon(
                            _sortNewestFirst
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 18,
                          ),
                          onPressed: () => setState(
                            () => _sortNewestFirst = !_sortNewestFirst,
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.done_all_rounded, size: 18),
                          label: const Text('Tout marquer lu'),
                          onPressed: _markAllRead,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ====== LISTE GROUPEE ======
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 44,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune notification',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modifie tes filtres ou reviens plus tard.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate.fixed(
                groups.entries.expand((entry) {
                  final sectionTitle = entry.key;
                  final list = entry.value;
                  return [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: PoliceBrand.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sectionTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: PoliceBrand.dark,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      color: PoliceBrand.surface,
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: PoliceBrand.radiusLg,
                      ),
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: list.length,
                          separatorBuilder: (_, __) => divider,
                          itemBuilder: (context, i) {
                            final n = list[i];
                            return Dismissible(
                              key: ValueKey(n.id),
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
                                if (dir == DismissDirection.startToEnd)
                                  _archive(n);
                                else
                                  _delete(n);
                                return true;
                              },
                              child: _NotifTile(
                                n: n,
                                icon: _iconFor(n.type),
                                color: _colorFor(n.type),
                                timeLabel: _timeLabel(n.createdAt),
                                priorityDot: _priorityDot(n.priority),
                                onTap: () => _toggleRead(n),
                                onMore: () => _showSheet(n),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ];
                }).toList(),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  // --- sous-composants ---

  Widget _typeChip(NotifType t, String label) {
    final color = _colorFor(t);
    return FilterChip(
      selectedColor: color.withOpacity(.12),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(t), size: 16, color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: _typeFilter == t,
      onSelected: (_) => setState(() => _typeFilter = t),
    );
  }

  Widget _dismissBg({
    required Color color,
    required IconData icon,
    required String label,
    required bool left,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: PoliceBrand.radiusLg,
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

  void _showSheet(AppNotification n) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_rounded),
                title: Text(
                  n.isRead ? 'Marquer comme non lu' : 'Marquer comme lu',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleRead(n);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_rounded),
                title: const Text('Archiver'),
                onTap: () {
                  Navigator.pop(context);
                  _archive(n);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _delete(n);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tu peux aussi réutiliser _BadgeFlag de ta SettingsPage.
/// Je le remets ici pour que le fichier soit autonome.
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

/// Tu peux aussi factoriser ce widget avec ta SettingsPage.
class _NotifTile extends StatelessWidget {
  final AppNotification n;
  final IconData icon;
  final Color color;
  final String timeLabel;
  final Color priorityDot;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _NotifTile({
    required this.n,
    required this.icon,
    required this.color,
    required this.timeLabel,
    required this.priorityDot,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !n.isRead;
    return InkWell(
      onTap: onTap,
      borderRadius: PoliceBrand.radiusSm,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(.35)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unread
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded),
                        onPressed: onMore,
                        tooltip: 'Options',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: priorityDot,
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
                      if (unread)
                        Row(
                          children: const [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.blueAccent,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Non lu',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
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
    );
  }
}
