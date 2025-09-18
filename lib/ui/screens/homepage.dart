// import 'package:flutter/material.dart';
// import 'package:niit/ui/screens/notification.dart';
// import 'package:niit/ui/screens/scan/scanhome.dart';
// import 'package:niit/ui/widgets/app_bar.dart';
// import 'package:niit/utils/colors.dart';

// class SizeConfig {
//   static late MediaQueryData _mediaQueryData;
//   static late double screenWidth;
//   static late double screenHeight;

//   void init(BuildContext context) {
//     _mediaQueryData = MediaQuery.of(context);
//     screenWidth = _mediaQueryData.size.width;
//     screenHeight = _mediaQueryData.size.height;
//   }

//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   double responsiveWidth(double percentage) =>
//       SizeConfig.screenWidth * percentage;
//   double responsiveHeight(double percentage) =>
//       SizeConfig.screenHeight * percentage;

//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     return Scaffold(
//       appBar: CustomAppBar(),
//       backgroundColor: AppColors.k_background_white,
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     height: responsiveHeight(0.07),
//                     width: responsiveWidth(0.2),
//                     child: Image.asset("assets/img/police_logo.png"),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.only(right: responsiveWidth(0.08)),
//                     child: Container(
//                       child: Text(
//                         "NIIT",
//                         style: TextStyle(
//                           fontSize: 36,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.k_primary_black,
//                         ),
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const NotificationHome(),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       child: Icon(
//                         Icons.notification_add_outlined,
//                         color: AppColors.k_primary_black,
//                         size: 28,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 20),
//               Container(
//                 child: Text(
//                   "Dans l’honneur, au service de la loi.",
//                   style: TextStyle(
//                     fontStyle: FontStyle.italic,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.k_primary_black,
//                   ),
//                 ),
//               ),
//               SizedBox(height: responsiveHeight(0.04)),
//               GridView.count(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//                 children: [
//                   _buildCard(
//                     context,
//                     Icons.document_scanner,
//                     'Détection de plaque',
//                     () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PlateRecognitionScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   _buildCard(context, Icons.assignment, 'Interventions', () {
//                     // Action à définir
//                   }),
//                   _buildCard(context, Icons.map, 'Géolocalisation', () {
//                     // Action à définir
//                   }),

//                   _buildCard(context, Icons.report, 'Rapports', () {
//                     // Action à définir
//                   }),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCard(
//     BuildContext context,
//     IconData icon,
//     String label,
//     VoidCallback onTap,
//   ) {
//     return Card(
//       color: AppColors.k_background_white,
//       elevation: 8,
//       shadowColor: AppColors.k_card_green.withOpacity(0.9),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(icon, size: 40, color: AppColors.k_primary_black),
//                 const SizedBox(height: 16),
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.k_primary_black,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niit/ui/screens/geolocalisation.dart';
import 'package:niit/ui/screens/interventions.dart';
import 'package:niit/ui/screens/messageqg.dart';
import 'package:niit/ui/screens/notification.dart';
import 'package:niit/ui/screens/redzone.dart';
import 'package:niit/ui/screens/report.dart';
import 'package:niit/ui/screens/scan/scanhome.dart';
import 'package:niit/ui/widgets/app_bar.dart';
import 'package:niit/utils/colors.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
  }

  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  late final AnimationController _titleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  double responsiveWidth(double p) => SizeConfig.screenWidth * p;
  double responsiveHeight(double p) => SizeConfig.screenHeight * p;

  @override
  void dispose() {
    _glowCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final isSmall = SizeConfig.screenWidth < 380;

    return Scaffold(
      backgroundColor: AppColors.k_background_white,
      appBar: CustomAppBar(),
      body: CustomScrollView(
        slivers: [
          // ---------- HEADER AI ----------
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              height: responsiveHeight(0.22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment(-0.9, -1),
                  end: Alignment(0.9, 1),
                  colors: [Color(0xFF0D0D0D), Color(0xFF1B1B1B)],
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
                  // Orbe IA animé (glow)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _glowCtrl,
                      builder: (_, __) {
                        final t = 0.55 + 0.45 * _glowCtrl.value;
                        return CustomPaint(
                          painter: _AiGlowPainter(intensity: t),
                        );
                      },
                    ),
                  ),
                  // Contenu du header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      children: [
                        // Logo encadré
                        Container(
                          width: isSmall ? 54 : 64,
                          height: isSmall ? 54 : 64,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Image.asset("assets/img/police_logo.png"),
                        ),
                        const SizedBox(width: 14),
                        // Titre + baseline
                        Expanded(
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _titleCtrl,
                              curve: Curves.easeOut,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (r) => const LinearGradient(
                                    colors: [Colors.white, Color(0xFFBDE6FF)],
                                  ).createShader(r),
                                  child: Text(
                                    "NIIT",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isSmall ? 28 : 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color:
                                          Colors.white, // masqué par ShaderMask
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Dans l’honneur, au service de la loi.",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Icône Notifications (effet pulse léger)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationHome(),
                              ),
                            );
                          },
                          child: AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (_, __) {
                              final t = _glowCtrl.value;
                              return Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.cyanAccent.withOpacity(
                                      0.35 + 0.35 * t,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 18,
                                      spreadRadius: -6,
                                      color: Colors.cyanAccent.withOpacity(
                                        0.18 + 0.12 * t,
                                      ),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- GRILLE D'ACTIONS ----------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 160),
            sliver: SliverGrid.count(
              crossAxisCount: SizeConfig.screenWidth < 500 ? 2 : 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                _FeatureCard(
                  icon: Icons.document_scanner,
                  label: 'Détection de plaque',
                  accent: Colors.cyanAccent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlateRecognitionScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Interventions',
                  accent: const Color(0xFF7CF5A2),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InterventionsPage(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.map_outlined,
                  label: 'Géolocalisation',
                  accent: const Color(0xFFFFD166),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GeolocationPage(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.report_outlined,
                  label: 'Rapports',
                  accent: const Color(0xFFFF8FA3),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.shield_outlined,
                  label: 'Zones rouges',
                  accent: const Color(0xFF89C2FF),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ZonesRougesPage(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.forum_outlined,
                  label: 'Messages QG',
                  accent: const Color(0xFFB9FBC0),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MessagesQGPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ====== Painter pour l'orbe IA (glow radial animé) ======
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

/// ====== Carte “verre + néon” avec micro-animation ======
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (down) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(.06)
        : Colors.white;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value; // 0..1
        return GestureDetector(
          onTapDown: (_) => _press(true),
          onTapCancel: () => _press(false),
          onTapUp: (_) {
            _press(false);
            widget.onTap();
          },
          child: Container(
            decoration: BoxDecoration(
              color: base.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.accent.withOpacity(.28 + .32 * t),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 22,
                  spreadRadius: -10,
                  offset: const Offset(0, 14),
                  color: widget.accent.withOpacity(.18 + .12 * t),
                ),
              ],
            ),
            child: Stack(
              children: [
                // halo intérieur léger
                Positioned.fill(
                  child: Opacity(
                    opacity: .08 + .10 * t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: RadialGradient(
                          center: const Alignment(0.2, -0.6),
                          radius: 1.0,
                          colors: [widget.accent, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                // contenu
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, size: 36, color: Colors.black87),
                        const SizedBox(height: 12),
                        Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
