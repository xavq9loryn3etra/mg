import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mafia_app/theme.dart';
import '../providers/app_provider.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDone() {
    ref.read(setTutorialSeenProvider)();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slides = [
      _Slide(
        icon: Icons.groups_rounded,
        title: 'WELCOME',
        description:
            'A party game of deception, deduction, and survival. Gather your friends and uncover the truth... or bluff your way to victory.',
        color: AppTheme.accent,
      ),
      const _Slide(
        icon: Icons.theater_comedy_rounded,
        title: 'THE NARRATOR',
        description:
            'The Master of Ceremonies. They do not play, but guide the story, manage the night phases, and reveal the morning tragedies.',
        color: Colors.white70,
      ),
      const _Slide(
        icon: Icons.gavel,
        title: 'THE GODFATHER',
        description:
            'The leader of the Mafia. Each night, decide who should be eliminated. You also have the final say on all Mafia actions.\n\nNote: You appear as Innocent to the Detective!',
        color: AppTheme.primary,
      ),
      const _Slide(
        icon: Icons.masks,
        title: 'THE MAFIA',
        description:
            'The secret strike team. You wake up each night to choose a victim. Blend in during the day to avoid suspicion.',
        color: AppTheme.primary,
      ),
      const _Slide(
        icon: Icons.health_and_safety,
        title: 'THE DOCTOR',
        description:
            'The guardian. Choose one player each night to save from a Mafia attack. You can even choose to save yourself!',
        color: AppTheme.success,
      ),
      const _Slide(
        icon: Icons.pets,
        title: 'THE RABID DOG',
        description:
            'The chaos element. Bite a player each night. If someone is bitten twice, they succumb to rabies and die.',
        color: Colors.orangeAccent,
      ),
      const _Slide(
        icon: Icons.search_rounded,
        title: 'THE DETECTIVE',
        description:
            'Each night, the Detective investigates one player. The Narrator will signal \'Yes\' if they are Mafia, or \'No\' otherwise.\n\nNote: The Godfather appears as \'No\' (Innocent) to the Detective!',
        color: Colors.blueAccent,
      ),
      const _Slide(
        icon: Icons.person,
        title: 'THE VILLAGERS',
        description:
            'The innocent majority. You have no night powers, but your logic and your vote during the day are the town\'s only weapons.',
        color: AppTheme.accent,
      ),
      const _Slide(
        icon: Icons.nightlight_round,
        title: 'NIGHT PHASE',
        description:
            'The village sleeps while special roles perform their secret actions. The Narrator wakes everyone up when morning comes.',
        color: Colors.deepPurpleAccent,
      ),
      const _Slide(
        icon: Icons.wb_sunny_rounded,
        title: 'DAY PHASE',
        description:
            'The village wakes up. Discuss the night\'s events, debate suspicions, and vote to eliminate a suspected Mafia member.',
        color: Colors.orangeAccent,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Glow
          _RadialGlowBackground(color: slides[_currentPage].color),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _onDone,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(slides[index], theme);
                    },
                  ),
                ),

                // Pagination dots and Next/Get Started button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dot indicator
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              slides.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                height: 6,
                                width: _currentPage == index ? 20 : 6,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? slides[index].color
                                      : Colors.white12,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage == slides.length - 1) {
                            _onDone();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutQuart,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          side: BorderSide(
                            color: slides[_currentPage].color.withOpacity(0.3),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == slides.length - 1
                              ? "GET STARTED"
                              : "NEXT",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: slides[_currentPage].color,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_Slide slide, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating Icon Animation
          TweenAnimationBuilder(
            key: ValueKey(slide.title),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.5 + (0.5 * value),
                  child: _FloatingIcon(icon: slide.icon, color: slide.color),
                ),
              );
            },
          ),
          const SizedBox(height: 60),
          Text(
            slide.title,
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 32,
              color: Colors.white,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            slide.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.7),
              height: 1.6,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _RadialGlowBackground extends StatelessWidget {
  final Color color;
  const _RadialGlowBackground({required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.2,
          colors: [color.withOpacity(0.15), Colors.black],
        ),
      ),
    );
  }
}

class _FloatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _FloatingIcon({required this.icon, required this.color});

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Icon(
            widget.icon,
            size: 120,
            color: widget.color.withOpacity(0.9),
            shadows: [
              Shadow(color: widget.color.withOpacity(0.5), blurRadius: 40),
            ],
          ),
        );
      },
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _Slide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
