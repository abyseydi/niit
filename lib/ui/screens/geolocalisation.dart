import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niit/ui/widgets/app_bar.dart';

class GeolocationPage extends StatefulWidget {
  const GeolocationPage({super.key});
  @override
  State<GeolocationPage> createState() => _GeolocationPageState();
}

class _GeolocationPageState extends State<GeolocationPage>
    with TickerProviderStateMixin {
  // --------- Animations (glow header + rafraîchissement carte) ---------
  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  Timer? _tick;
  double _t = 0; // temps pour le déplacement des patrouilles / azimut

  // --------- Etat UI ---------
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showUnits = true;
  bool _showIncidents = true;
  bool _showRedZones = true;
  bool _followMe = false;

  // --------- "Mon" état (mock) ---------
  Offset _me = const Offset(0.45, 0.55); // coordonnées normalisées [0..1] (x,y)
  double _azimuth = 0.0; // radians

  // --------- Données mock ---------
  final List<_Unit> _units = [
    _Unit(id: 'U-13', name: 'Patrouille U-13', pos: const Offset(0.30, 0.35)),
    _Unit(id: 'U-07', name: 'Patrouille U-07', pos: const Offset(0.70, 0.25)),
    _Unit(id: 'U-21', name: 'Patrouille U-21', pos: const Offset(0.75, 0.70)),
  ];
  final List<_Incident> _incidents = [
    _Incident(
      id: 'A-1',
      title: 'Accrochage mineur',
      pos: const Offset(0.62, 0.42),
      severity: 2,
    ),
    _Incident(
      id: 'R-3',
      title: 'Rassemblement signalé',
      pos: const Offset(0.25, 0.62),
      severity: 3,
    ),
    _Incident(
      id: 'I-2',
      title: 'Infraction vitesse',
      pos: const Offset(0.52, 0.18),
      severity: 1,
    ),
  ];
  final List<List<Offset>> _redZones = [
    // Polygone 1
    [
      const Offset(0.18, 0.18),
      const Offset(0.28, 0.22),
      const Offset(0.26, 0.32),
      const Offset(0.15, 0.30),
    ],
    // Polygone 2
    [
      const Offset(0.68, 0.65),
      const Offset(0.80, 0.60),
      const Offset(0.84, 0.74),
      const Offset(0.72, 0.78),
    ],
  ];

  // --------- KPIs (calculés à la volée) ---------
  int get _kpiUnitsOnDuty => _units.length;
  int get _kpiIncidentsNearby => _incidents.length;
  int get _kpiRedZones => _redZones.length;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 60), (_) {
      setState(() {
        _t += 0.016; // approx 60 FPS * 0.016
        _azimuth = (_azimuth + 0.01) % (2 * pi);

        // patrouilles se déplacent en micro-orbites
        for (var i = 0; i < _units.length; i++) {
          final u = _units[i];
          final r = 0.006 + 0.002 * (i + 1);
          final w = 0.3 + 0.1 * i;
          final dx = r * cos(w * _t + i);
          final dy = r * sin(w * _t + i);
          _units[i] = u.copyWith(
            pos: Offset(
              (u.pos.dx + dx).clamp(0.05, 0.95),
              (u.pos.dy + dy).clamp(0.05, 0.95),
            ),
          );
        }

        // si suivi activé, la "caméra" (centre) suit _me (gérée dans painter via _followMe)
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

  // --------- Actions ---------
  void _centerOnMe() {
    HapticFeedback.lightImpact();
    // Pas de camera réelle ici, mais on force un rebuild (painter recentre si _followMe = true)
    setState(() {
      _followMe = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suivi activé : centré sur votre position')),
    );
  }

  void _toggleFollow() {
    HapticFeedback.selectionClick();
    setState(() => _followMe = !_followMe);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_followMe ? 'Suivi activé' : 'Suivi désactivé')),
    );
  }

  void _simulateRoute() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Itinéraire IA simulé (mock)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = _kpiIncidentsNearby; // pour l’info header

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: CustomAppBar(),

      body: CustomScrollView(
        slivers: [
          // ========= HEADER IA =========
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
                  // Orbe IA
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
                                  "Géolocalisation",
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
                                "$unread incident(s) signalé(s) • ${_kpiUnitsOnDuty} unité(s) en service",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HeaderAction(
                          icon: Icons.route_outlined,
                          tooltip: "Itinéraire IA",
                          onTap: _simulateRoute,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========= KPIs =========
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: "Unités",
                      value: '$_kpiUnitsOnDuty',
                      accent: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: "Incidents",
                      value: '$_kpiIncidentsNearby',
                      accent: const Color(0xFFFFD166),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      label: "Zones rouges",
                      value: '$_kpiRedZones',
                      accent: const Color(0xFF7CF5A2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========= Recherche + filtres =========
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
                      hintText: 'Rechercher un lieu / unité / incident…',
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
                        FilterChip(
                          label: const Text("Unités"),
                          selected: _showUnits,
                          selectedColor: Colors.cyanAccent.withOpacity(.18),
                          onSelected: (v) => setState(() => _showUnits = v),
                        ),
                        FilterChip(
                          label: const Text("Incidents"),
                          selected: _showIncidents,
                          selectedColor: const Color(
                            0xFFFF8FA3,
                          ).withOpacity(.18),
                          onSelected: (v) => setState(() => _showIncidents = v),
                        ),
                        FilterChip(
                          label: const Text("Zones rouges"),
                          selected: _showRedZones,
                          selectedColor: const Color(
                            0xFF7CF5A2,
                          ).withOpacity(.18),
                          onSelected: (v) => setState(() => _showRedZones = v),
                        ),
                        InputChip(
                          label: Text(
                            _followMe ? 'Suivi activé' : 'Suivi désactivé',
                          ),
                          avatar: Icon(
                            _followMe
                                ? Icons.center_focus_strong
                                : Icons.center_focus_weak,
                            size: 18,
                          ),
                          onPressed: _toggleFollow,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========= CARTE (CustomPainter) =========
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
                        painter: _MapPainter(
                          me: _me,
                          azimuth: _azimuth,
                          units: _showUnits ? _units : const [],
                          incidents: _showIncidents ? _incidents : const [],
                          redZones: _showRedZones ? _redZones : const [],
                          t: _t,
                          followMe: _followMe,
                          cursor: _searchCtrl.text.trim(),
                        ),
                        size: Size.infinite,
                      ),
                      // Actions flottantes sur la carte
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Column(
                          children: [
                            _MapMiniBtn(
                              icon: Icons.my_location,
                              tooltip: 'Centrer sur moi',
                              onTap: _centerOnMe,
                            ),
                            const SizedBox(height: 8),
                            _MapMiniBtn(
                              icon: Icons.route_outlined,
                              tooltip: 'Itinéraire IA',
                              onTap: _simulateRoute,
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

          // ========= Listes contextuelles =========
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_showUnits) ...[
                    _SectionTitle('Unités à proximité'),
                    const SizedBox(height: 8),
                    ..._units.map(
                      (u) => _ListCard(
                        title: u.name,
                        subtitle:
                            'ID ${u.id} • Distance ~${_fmtDist(_me, u.pos)}',
                        accent: Colors.cyanAccent,
                        trailing: const Icon(Icons.call_made_rounded),
                        onTap: () => _openUnit(u),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_showIncidents) ...[
                    _SectionTitle('Incidents récents'),
                    const SizedBox(height: 8),
                    ..._incidents.map(
                      (i) => _ListCard(
                        title: i.title,
                        subtitle:
                            'Gravité ${i.severity} • À ~${_fmtDist(_me, i.pos)}',
                        accent: const Color(0xFFFF8FA3),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () => _openIncident(i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------- Helpers UI ---------
  String _fmtDist(Offset a, Offset b) {
    final d = (a - b).distance; // 0..~1
    // On simule ~km : carte normalisée => ~ 10 km max
    final km = (d * 10).clamp(0, 99).toStringAsFixed(1);
    return '$km km';
  }

  void _openUnit(_Unit u) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              u.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.tag_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(u.id),
                const Spacer(),
                const Icon(Icons.map_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('~${_fmtDist(_me, u.pos)}'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Itinéraire'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Contacter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openIncident(_Incident i) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              i.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.priority_high_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text('Gravité ${i.severity}'),
                const Spacer(),
                const Icon(
                  Icons.pin_drop_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text('~${_fmtDist(_me, i.pos)}'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Itinéraire'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.task_alt_outlined),
                    label: const Text('Créer intervention'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ======================== Modèles simples ======================== */
class _Unit {
  final String id;
  final String name;
  final Offset pos; // normalisé [0..1]
  const _Unit({required this.id, required this.name, required this.pos});

  _Unit copyWith({String? id, String? name, Offset? pos}) =>
      _Unit(id: id ?? this.id, name: name ?? this.name, pos: pos ?? this.pos);
}

class _Incident {
  final String id;
  final String title;
  final Offset pos;
  final int severity; // 1..3
  const _Incident({
    required this.id,
    required this.title,
    required this.pos,
    required this.severity,
  });
}

/* ======================== Painter Carte IA ======================== */
class _MapPainter extends CustomPainter {
  final Offset me;
  final double azimuth;
  final List<_Unit> units;
  final List<_Incident> incidents;
  final List<List<Offset>> redZones;
  final double t; // temps
  final bool followMe;
  final String cursor; // recherche

  _MapPainter({
    required this.me,
    required this.azimuth,
    required this.units,
    required this.incidents,
    required this.redZones,
    required this.t,
    required this.followMe,
    required this.cursor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    // fond “carte” stylisé (grille + routes simplifiées)
    _drawGrid(canvas, size);
    _drawRoutes(canvas, size);

    // zones rouges
    for (final poly in redZones) {
      _drawRedZone(canvas, size, poly);
    }

    // incidents
    for (final i in incidents) {
      _drawIncident(canvas, size, i);
    }

    // vous (agent)
    _drawMe(canvas, size);

    // unités
    for (final u in units) {
      _drawUnit(canvas, size, u);
    }

    // radar/anneaux si recherche active
    if (cursor.isNotEmpty) {
      _drawSearchPulse(canvas, size);
    }
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
    // parcours “ville” abstrait
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

  void _drawRedZone(Canvas canvas, Size size, List<Offset> poly) {
    final tr = (Offset o) => Offset(o.dx * size.width, o.dy * size.height);
    final path = Path()..moveTo(tr(poly.first).dx, tr(poly.first).dy);
    for (int i = 1; i < poly.length; i++) {
      path.lineTo(tr(poly[i]).dx, tr(poly[i]).dy);
    }
    path.close();

    final fill = Paint()..color = const Color(0xFFD93025).withOpacity(.12);
    final stroke = Paint()
      ..color = const Color(0xFFD93025).withOpacity(.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawIncident(Canvas canvas, Size size, _Incident inc) {
    final pos = Offset(inc.pos.dx * size.width, inc.pos.dy * size.height);
    final c = [
      const Color(0xFFFF8FA3),
      const Color(0xFFFFD1DC),
    ][inc.severity % 2];
    final fill = Paint()..color = c.withOpacity(.18);
    final stroke = Paint()
      ..color = c.withOpacity(.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // halo
    canvas.drawCircle(pos, 14, fill);
    // pin
    final pin = Path()
      ..addOval(Rect.fromCircle(center: pos, radius: 6))
      ..moveTo(pos.dx, pos.dy + 6)
      ..lineTo(pos.dx, pos.dy + 14);
    canvas.drawPath(pin, stroke);

    // étiquette
    _drawLabel(canvas, pos + const Offset(10, -18), inc.title, stroke.color);
  }

  void _drawUnit(Canvas canvas, Size size, _Unit u) {
    final pos = Offset(u.pos.dx * size.width, u.pos.dy * size.height);
    final fill = Paint()..color = Colors.cyanAccent.withOpacity(.18);
    final stroke = Paint()
      ..color = Colors.cyanAccent.withOpacity(.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawCircle(pos, 10, fill);
    canvas.drawCircle(pos, 10, stroke);
    _drawLabel(canvas, pos + const Offset(10, -16), u.id, stroke.color);
  }

  void _drawMe(Canvas canvas, Size size) {
    // transformation “caméra suit” (optionnelle)
    canvas.save();
    if (followMe) {
      final center = Offset(size.width / 2, size.height / 2);
      final pos = Offset(me.dx * size.width, me.dy * size.height);
      final dx = center.dx - pos.dx;
      final dy = center.dy - pos.dy;
      canvas.translate(dx, dy);
    }

    final pos = Offset(me.dx * size.width, me.dy * size.height);

    // azimut
    final dir = Offset(cos(azimuth), sin(azimuth));
    final arrowEnd = pos + dir * 26;
    final pDir = Paint()
      ..color = Colors.blueAccent.withOpacity(.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos, arrowEnd, pDir);

    // halo & point
    final halo = Paint()..color = Colors.blueAccent.withOpacity(.18);
    canvas.drawCircle(pos, 14, halo);
    final mePaint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(pos, 7, mePaint);

    // label
    _drawLabel(canvas, pos + const Offset(10, -18), "Vous", Colors.blueAccent);
    canvas.restore();
  }

  void _drawSearchPulse(Canvas canvas, Size size) {
    final center = Offset(size.width * .82, size.height * .22);
    final r = 30.0 + 12.0 * sin(2 * pi * (t % 1));
    final p = Paint()
      ..color = Colors.black.withOpacity(.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, r, p);
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
    )..layout(maxWidth: 160);
    final bg = Paint()..color = Colors.white.withOpacity(.85);
    final rect = Rect.fromLTWH(
      pos.dx - 6,
      pos.dy - 2,
      tp.width + 12,
      tp.height + 4,
    );
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rr, bg);
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.t != t ||
      old.followMe != followMe ||
      old.cursor != cursor ||
      old.units != units ||
      old.incidents != incidents ||
      old.redZones != redZones ||
      old.me != me ||
      old.azimuth != azimuth;
}

/* ======================== Cartes & éléments UI ======================== */

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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _ListCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(.28)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            spreadRadius: -10,
            offset: const Offset(0, 12),
            color: accent.withOpacity(.14),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: trailing,
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
          child: const Icon(Icons.route_outlined, color: Colors.white),
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
