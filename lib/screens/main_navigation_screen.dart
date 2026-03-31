import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'health_screen.dart';
import 'coach_chat_screen.dart';
import 'timer_screen.dart';
import '../stores/nutrition_store.dart';
import '../widgets/pulsing_particle_sphere.dart';
import '../styles.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTab;
  final bool openSleepTab;

  const MainNavigationScreen({
    super.key,
    this.initialTab = 1,
    this.openSleepTab = false,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex = widget.initialTab;
  late final PageController _pageController =
      PageController(initialPage: widget.initialTab);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionStore>().initialize();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  static const _iconPaths = [
    'assets/ionicons.designerpack/stats-chart.svg',
    'assets/ionicons.designerpack/chatbubble.svg',
    'assets/ionicons.designerpack/heart.svg',
    'assets/progress-ring.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const PageScrollPhysics(),
            children: [
              const ProgressScreen(),
              const CoachChatScreen(),
              HealthScreen(
                  initialSubTab: widget.openSleepTab ? 1 : 0),
              const TimerScreen(),
              const HomeScreen(),
            ],
          ),

          // Bottom bar area
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Glass nav bar (3 tabs)
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: CustomPaint(
                          painter: _GlassNavPainter(),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final tabWidth = constraints.maxWidth / 4;
                              const pillW = 52.0;
                              const pillH = 43.0;
                              final clampedIndex =
                                  _currentIndex.clamp(0, 3);
                              return Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    left: (_currentIndex <= 3
                                            ? clampedIndex
                                            : -1) *
                                        tabWidth +
                                        (tabWidth - pillW) / 2,
                                    top: (56 - pillH) / 2,
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      opacity:
                                          _currentIndex <= 3 ? 1.0 : 0.0,
                                      child: Container(
                                        width: pillW,
                                        height: pillH,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(19),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(4, (i) {
                                      final isSelected =
                                          _currentIndex == i;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () => _onNavTapped(i),
                                          behavior:
                                              HitTestBehavior.opaque,
                                          child: SizedBox(
                                            height: 56,
                                            child: Center(
                                              child: _iconPaths[i] ==
                                                      'assets/progress-ring.svg'
                                                  ? Opacity(
                                                      opacity: isSelected
                                                          ? 1.0
                                                          : 0.4,
                                                      child: SvgPicture.asset(
                                                        _iconPaths[i],
                                                        width: 22,
                                                        height: 22,
                                                      ),
                                                    )
                                                  : SvgPicture.asset(
                                                      _iconPaths[i],
                                                      width: 22,
                                                      height: 22,
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.white
                                                                .withValues(
                                                                    alpha:
                                                                        0.4),
                                                        BlendMode.srcIn,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Floating workout orb button
                    GestureDetector(
                      onTap: () => _onNavTapped(4),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF111111),
                          border: Border.all(
                            color: _currentIndex == 4
                                ? AppColors.overlay.withValues(alpha: 0.20)
                                : AppColors.overlay.withValues(alpha: 0.10),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: PulsingParticleSphere(
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassNavPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(32));

    final fill = Paint()..color = const Color(0xFF111111);
    canvas.drawRRect(rr, fill);

    final borderPath = Path()..addRRect(rr);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.overlay.withValues(alpha: 0.0),
          AppColors.overlay.withValues(alpha: 0.18),
          AppColors.overlay.withValues(alpha: 0.18),
          AppColors.overlay.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.15, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawPath(borderPath, borderPaint);

    final topHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.overlay.withValues(alpha: 0.0),
          AppColors.overlay.withValues(alpha: 0.12),
          AppColors.overlay.withValues(alpha: 0.12),
          AppColors.overlay.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.8, 1.0],
      ).createShader(rect);

    canvas.drawLine(
      Offset(32, 0.25),
      Offset(size.width - 32, 0.25),
      topHighlight,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
