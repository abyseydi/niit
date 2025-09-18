import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================ Modèles ============================
enum QgChannel { broadcast, alert, directive, direct }

enum QgPriority { low, normal, high, critical }

class QgMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime time;
  final bool isMe;
  final int attachments; // mock
  final bool delivered; // accusé
  final bool read; // lu

  QgMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    this.attachments = 0,
    this.delivered = true,
    this.read = false,
  });

  QgMessage copyWith({bool? delivered, bool? read}) => QgMessage(
    id: id,
    sender: sender,
    text: text,
    time: time,
    isMe: isMe,
    attachments: attachments,
    delivered: delivered ?? this.delivered,
    read: read ?? this.read,
  );
}

class QgThread {
  final String id;
  String title;
  QgChannel channel;
  QgPriority priority;
  int unread;
  bool pinned;
  bool muted;
  DateTime lastTime;
  String lastPreview;
  int attachments;
  List<String> participants;
  List<String> tags;
  List<QgMessage> messages;

  QgThread({
    required this.id,
    required this.title,
    required this.channel,
    required this.priority,
    required this.unread,
    required this.pinned,
    required this.muted,
    required this.lastTime,
    required this.lastPreview,
    required this.attachments,
    required this.participants,
    required this.tags,
    required this.messages,
  });
}

/// ============================ Page ============================

class MessagesQGPage extends StatefulWidget {
  const MessagesQGPage({super.key});
  @override
  State<MessagesQGPage> createState() => _MessagesQGPageState();
}

class _MessagesQGPageState extends State<MessagesQGPage>
    with TickerProviderStateMixin {
  // ----------------- Données mock -----------------
  final List<QgThread> _all = [
    QgThread(
      id: 't1',
      title: 'Diffusion — Brief opérationnel 18h',
      channel: QgChannel.broadcast,
      priority: QgPriority.normal,
      unread: 2,
      pinned: true,
      muted: false,
      lastTime: DateTime.now().subtract(const Duration(minutes: 5)),
      lastPreview: 'Rappel consignes zones rouges Colobane / Corniche.',
      attachments: 1,
      participants: const ['QG', 'Unités'],
      tags: const ['brief', 'soirée'],
      messages: [
        QgMessage(
          id: 'm1',
          sender: 'QG',
          text:
              'Brief 18h — consignes zones rouges Colobane/Corniche. Patrols renforcées.',
          time: DateTime.now().subtract(const Duration(minutes: 35)),
          isMe: false,
          attachments: 1,
          delivered: true,
          read: true,
        ),
        QgMessage(
          id: 'm2',
          sender: 'QG',
          text: 'Rappel : signaler tout attroupement > 10 pers.',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          isMe: false,
          delivered: true,
          read: false,
        ),
      ],
    ),
    QgThread(
      id: 't2',
      title: 'ALERTE — Véhicule signalé DK-4821-AB',
      channel: QgChannel.alert,
      priority: QgPriority.critical,
      unread: 1,
      pinned: true,
      muted: false,
      lastTime: DateTime.now().subtract(const Duration(minutes: 8)),
      lastPreview: 'Caméra IA : passage HLM Grand Yoff.',
      attachments: 0,
      participants: const ['QG', 'U-13', 'P-7'],
      tags: const ['plaque', 'zone rouge'],
      messages: [
        QgMessage(
          id: 'm1',
          sender: 'QG',
          text: 'Véhicule DK-4821-AB repéré à HLM Grand Yoff. Priorité haute.',
          time: DateTime.now().subtract(const Duration(minutes: 12)),
          isMe: false,
          delivered: true,
          read: false,
        ),
      ],
    ),
    QgThread(
      id: 't3',
      title: 'Directive — Contrôles Corniche 22-02',
      channel: QgChannel.directive,
      priority: QgPriority.high,
      unread: 0,
      pinned: false,
      muted: false,
      lastTime: DateTime.now().subtract(const Duration(hours: 2)),
      lastPreview: 'Itinéraire mis à jour.',
      attachments: 2,
      participants: const ['QG', 'P-7'],
      tags: const ['contrôle', 'itinéraire'],
      messages: [
        QgMessage(
          id: 'm1',
          sender: 'QG',
          text: 'Nouveau point de contrôle à 22:15 — plan joint.',
          time: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
          isMe: false,
        ),
        QgMessage(
          id: 'm2',
          sender: 'Moi',
          text: 'Bien reçu.',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          isMe: true,
          delivered: true,
          read: true,
        ),
      ],
    ),
    QgThread(
      id: 't4',
      title: 'Direct — QG ▶︎ Moi',
      channel: QgChannel.direct,
      priority: QgPriority.low,
      unread: 0,
      pinned: false,
      muted: false,
      lastTime: DateTime.now().subtract(const Duration(hours: 5)),
      lastPreview: 'Merci pour le retour.',
      attachments: 0,
      participants: const ['QG', 'Moi'],
      tags: const ['direct'],
      messages: [
        QgMessage(
          id: 'm1',
          sender: 'QG',
          text: 'Peux-tu confirmer la relève à 23:00 ?',
          time: DateTime.now().subtract(const Duration(hours: 5, minutes: 10)),
          isMe: false,
        ),
        QgMessage(
          id: 'm2',
          sender: 'Moi',
          text: 'Confirmé.',
          time: DateTime.now().subtract(const Duration(hours: 5)),
          isMe: true,
          delivered: true,
          read: true,
        ),
      ],
    ),
  ];

  // ----------------- État UI -----------------
  final _searchCtrl = TextEditingController();
  QgChannel? _channelFilter;
  QgPriority? _prioFilter;
  bool _onlyPinned = false;
  bool _sortNewestFirst = true;

  // Header glow
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

  // ----------------- Helpers -----------------
  int get _kpiBroadcast =>
      _all.where((t) => t.channel == QgChannel.broadcast).length;
  int get _kpiAlert => _all.where((t) => t.channel == QgChannel.alert).length;
  int get _kpiDirective =>
      _all.where((t) => t.channel == QgChannel.directive).length;
  int get _kpiDirect => _all.where((t) => t.channel == QgChannel.direct).length;
  int get _kpiUnread => _all.fold(0, (p, e) => p + e.unread);

  Color _channelAccent(QgChannel c) {
    switch (c) {
      case QgChannel.broadcast:
        return Colors.cyanAccent;
      case QgChannel.alert:
        return const Color(0xFFFF8FA3);
      case QgChannel.directive:
        return const Color(0xFFFFD166);
      case QgChannel.direct:
        return const Color(0xFF7CF5A2);
    }
  }

  IconData _channelIcon(QgChannel c) {
    switch (c) {
      case QgChannel.broadcast:
        return Icons.campaign_outlined;
      case QgChannel.alert:
        return Icons.warning_amber_rounded;
      case QgChannel.directive:
        return Icons.rule_folder_outlined;
      case QgChannel.direct:
        return Icons.forum_outlined;
    }
  }

  Color _prioColor(QgPriority p) {
    switch (p) {
      case QgPriority.low:
        return Colors.teal;
      case QgPriority.normal:
        return Colors.blueGrey;
      case QgPriority.high:
        return Colors.redAccent;
      case QgPriority.critical:
        return const Color(0xFFD93025);
    }
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'à l’instant';
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays} j';
  }

  // ----------------- Filtrage -----------------
  List<QgThread> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _all.where((t) {
      if (_channelFilter != null && t.channel != _channelFilter) return false;
      if (_prioFilter != null && t.priority != _prioFilter) return false;
      if (_onlyPinned && !t.pinned) return false;
      if (q.isEmpty) return true;
      final hay = [
        t.title,
        t.lastPreview,
        ...t.tags,
        ...t.participants,
        ...t.messages.map((m) => m.text),
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();

    list.sort(
      (a, b) => _sortNewestFirst
          ? b.lastTime.compareTo(a.lastTime)
          : a.lastTime.compareTo(b.lastTime),
    );
    return list;
  }

  // ----------------- Actions threads -----------------
  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _togglePin(QgThread t) {
    setState(() => t.pinned = !t.pinned);
    _snack(t.pinned ? 'Fil épinglé' : 'Fil désépinglé');
  }

  void _toggleMute(QgThread t) {
    setState(() => t.muted = !t.muted);
    _snack(t.muted ? 'Fil en mode muet' : 'Notifications activées');
  }

  void _markRead(QgThread t) {
    setState(() => t.unread = 0);
  }

  void _deleteThread(QgThread t) {
    setState(() => _all.removeWhere((x) => x.id == t.id));
    _snack('Fil supprimé');
  }

  void _newThread() {
    final title = TextEditingController();
    QgChannel chan = QgChannel.direct;
    QgPriority prio = QgPriority.normal;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Sujet / titre'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<QgChannel>(
              value: chan,
              items: QgChannel.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => chan = v ?? chan,
              decoration: const InputDecoration(labelText: 'Canal'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<QgPriority>(
              value: prio,
              items: QgPriority.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => prio = v ?? prio,
              decoration: const InputDecoration(labelText: 'Priorité'),
            ),
          ],
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
                  QgThread(
                    id: 't${DateTime.now().millisecondsSinceEpoch}',
                    title: title.text.trim(),
                    channel: chan,
                    priority: prio,
                    unread: 0,
                    pinned: false,
                    muted: false,
                    lastTime: DateTime.now(),
                    lastPreview: '—',
                    attachments: 0,
                    participants: const ['QG', 'Moi'],
                    tags: const [],
                    messages: [],
                  ),
                );
              });
              Navigator.pop(context);
              _snack('Fil créé');
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  // ----------------- Build -----------------
  @override
  Widget build(BuildContext context) {
    final threads = _filtered;

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
                                  'Messages QG',
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
                                '$_kpiUnread non lus • ${_all.length} fils',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HeaderAction(
                          icon: Icons.add_comment_outlined,
                          tooltip: 'Nouveau',
                          onTap: _newThread,
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
                      label: 'Diffusions',
                      value: '$_kpiBroadcast',
                      accent: _channelAccent(QgChannel.broadcast),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'Alertes',
                      value: '$_kpiAlert',
                      accent: _channelAccent(QgChannel.alert),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'Directives',
                      value: '$_kpiDirective',
                      accent: _channelAccent(QgChannel.directive),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: 'Directs',
                      value: '$_kpiDirect',
                      accent: _channelAccent(QgChannel.direct),
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
                      hintText: 'Rechercher (sujet, texte, tag, participant)…',
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
                              _channelFilter = null;
                              _prioFilter = null;
                              _onlyPinned = false;
                            });
                          },
                        ),
                        _chipChannel(QgChannel.broadcast, 'Diffusions'),
                        _chipChannel(QgChannel.alert, 'Alertes'),
                        _chipChannel(QgChannel.directive, 'Directives'),
                        _chipChannel(QgChannel.direct, 'Directs'),
                        _chipPrio(QgPriority.critical, 'Critique'),
                        _chipPrio(QgPriority.high, 'Haut'),
                        FilterChip(
                          label: const Text('Épinglés'),
                          selected: _onlyPinned,
                          selectedColor: Colors.black.withOpacity(.06),
                          onSelected: (v) => setState(() => _onlyPinned = v),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== Liste de fils =====
          if (threads.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mark_chat_unread_outlined,
                      size: 44,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun message',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modifie tes filtres ou crée un message.',
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
                itemCount: threads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = threads[i];
                  return Dismissible(
                    key: ValueKey(t.id),
                    background: _dismissBg(
                      color: Colors.blueGrey,
                      icon: Icons.notifications_off_outlined,
                      label: t.muted ? 'Réactiver' : 'Muet',
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
                        _toggleMute(t);
                      } else {
                        _deleteThread(t);
                      }
                      return true;
                    },
                    child: _ThreadCard(
                      t: t,
                      accent: _channelAccent(t.channel),
                      channelIcon: _channelIcon(t.channel),
                      prioColor: _prioColor(t.priority),
                      timeLabel: _ago(t.lastTime),
                      onTap: () => _openThread(t),
                      onPin: () => _togglePin(t),
                      onMarkRead: () => _markRead(t),
                    ),
                  );
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _newThread,
      //   icon: const Icon(Icons.mode_comment_outlined),
      //   label: const Text('Nouveau'),
      // ),
    );
  }

  // ----------------- Widgets auxiliaires -----------------
  Widget _chipChannel(QgChannel c, String label) => FilterChip(
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_channelIcon(c), size: 16),
        const SizedBox(width: 6),
        Text(label),
      ],
    ),
    selected: _channelFilter == c,
    selectedColor: _channelAccent(c).withOpacity(.16),
    onSelected: (_) => setState(() => _channelFilter = c),
  );

  Widget _chipPrio(QgPriority p, String label) => FilterChip(
    label: Text(label),
    selected: _prioFilter == p,
    selectedColor: _prioColor(p).withOpacity(.12),
    onSelected: (_) => setState(() => _prioFilter = p),
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

  void _openThread(QgThread t) {
    // ouvrir la fiche en bottom sheet (messagerie)
    _markRead(t);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ThreadSheet(
        thread: t,
        channelIcon: _channelIcon(t.channel),
        accent: _channelAccent(t.channel),
        prioColor: _prioColor(t.priority),
        onSend: (text) {
          if (text.trim().isEmpty) return;
          setState(() {
            final msg = QgMessage(
              id: 'm${DateTime.now().millisecondsSinceEpoch}',
              sender: 'Moi',
              text: text.trim(),
              time: DateTime.now(),
              isMe: true,
              delivered: true,
              read: false,
            );
            t.messages.add(msg);
            t.lastTime = msg.time;
            t.lastPreview = msg.text;
          });
        },
      ),
    );
  }
}

/// ============================ Widgets ============================

class _ThreadCard extends StatelessWidget {
  final QgThread t;
  final Color accent;
  final IconData channelIcon;
  final Color prioColor;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onMarkRead;

  const _ThreadCard({
    required this.t,
    required this.accent,
    required this.channelIcon,
    required this.prioColor,
    required this.timeLabel,
    required this.onTap,
    required this.onPin,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(.28), width: 1.1),
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              spreadRadius: -10,
              offset: const Offset(0, 14),
              color: accent.withOpacity(.12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              // canal
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(.35)),
                ),
                child: Icon(channelIcon, color: accent),
              ),
              const SizedBox(width: 12),
              // contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // première ligne: titre + actions
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (t.pinned) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.push_pin,
                                  size: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ],
                            ],
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    // aperçu
                    Row(
                      children: [
                        if (t.attachments > 0) ...[
                          const Icon(
                            Icons.attachment,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            t.lastPreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // meta: priorité + participants + non lus
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: prioColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            t.participants.join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (t.unread > 0)
                          GestureDetector(
                            onTap: onMarkRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.85),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${t.unread}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onPin,
                          child: Icon(
                            Icons.push_pin_outlined,
                            size: 18,
                            color: Colors.grey.shade700,
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

class _ThreadSheet extends StatefulWidget {
  final QgThread thread;
  final IconData channelIcon;
  final Color accent;
  final Color prioColor;
  final ValueChanged<String> onSend;

  const _ThreadSheet({
    required this.thread,
    required this.channelIcon,
    required this.accent,
    required this.prioColor,
    required this.onSend,
  });

  @override
  State<_ThreadSheet> createState() => _ThreadSheetState();
}

class _ThreadSheetState extends State<_ThreadSheet> {
  final _composer = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _typingTimer;
  bool _hqTyping = false;

  @override
  void initState() {
    super.initState();
    // Simulation : HQ tape après ouverture si dernier message est le vôtre
    final last = widget.thread.messages.isNotEmpty
        ? widget.thread.messages.last
        : null;
    if (last != null && last.isMe) {
      _typingTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _hqTyping = true);
        _typingTimer = Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _hqTyping = false);
        });
      });
    }
  }

  @override
  void dispose() {
    _composer.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _sendQuick(String text) {
    HapticFeedback.selectionClick();
    widget.onSend(text);
    _composer.clear();
    _scrollToEnd();
  }

  void _send() {
    final text = _composer.text;
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    _composer.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header mini
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: widget.accent.withOpacity(.45)),
                    ),
                    child: Icon(widget.channelIcon, color: widget.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.prioColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                t.participants.join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Messages
            Flexible(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: t.messages.length + (_hqTyping ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_hqTyping && i == t.messages.length) {
                    return _TypingBubble(accent: widget.accent);
                  }
                  final m = t.messages[i];
                  return Align(
                    alignment: m.isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                          color: m.isMe ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (m.isMe ? Colors.black : Colors.black12),
                          ),
                          boxShadow: !m.isMe
                              ? [
                                  const BoxShadow(
                                    blurRadius: 16,
                                    spreadRadius: -10,
                                    color: Colors.black12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: m.isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!m.isMe)
                              Text(
                                m.sender,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            if (!m.isMe) const SizedBox(height: 2),
                            Text(
                              m.text,
                              style: TextStyle(
                                color: m.isMe ? Colors.white : Colors.black87,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _time(m.time),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: m.isMe
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                if (m.isMe) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    m.read ? Icons.done_all : Icons.done,
                                    size: 14,
                                    color: m.read
                                        ? Colors.lightBlueAccent
                                        : Colors.white70,
                                  ),
                                ],
                                if (m.attachments > 0) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.attachment,
                                    size: 14,
                                    color: m.isMe
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                  ),
                                  Text(
                                    '${m.attachments}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: m.isMe
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Réponses rapides
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _QuickBtn(
                      label: 'Reçu ✔︎',
                      onTap: () => _sendQuick('Reçu ✔︎'),
                    ),
                    _QuickBtn(
                      label: 'En route',
                      onTap: () => _sendQuick('En route'),
                    ),
                    _QuickBtn(
                      label: 'Sur site',
                      onTap: () => _sendQuick('Sur site'),
                    ),
                    _QuickBtn(label: 'RAS', onTap: () => _sendQuick('RAS')),
                  ],
                ),
              ),
            ),

            // Composer
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file_outlined),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Écrire au QG…',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Envoyer'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _TypingBubble extends StatelessWidget {
  final Color accent;
  const _TypingBubble({required this.accent});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(blurRadius: 16, spreadRadius: -10, color: Colors.black12),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(accent: accent, delay: 0),
            const SizedBox(width: 3),
            _Dot(accent: accent, delay: 120),
            const SizedBox(width: 3),
            _Dot(accent: accent, delay: 240),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color accent;
  final int delay;
  const _Dot({required this.accent, required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = ((_ctrl.value * 1000 + widget.delay) % 1000) / 1000.0; // 0..1
        final y = sin(2 * pi * t);
        final s = 1 + 0.25 * (y.clamp(0, 1));
        return Transform.scale(
          scale: s,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.accent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
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

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      elevation: 0,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.black12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
