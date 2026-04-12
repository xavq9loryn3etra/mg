import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
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
    final slides = [
      _Slide(
        icon: Icons.groups_rounded,
        title: 'Welcome to Mafia',
        description:
            'A party game of deception, deduction, and survival. Gather your friends and uncover the truth... or bluff your way to victory.',
        color: Theme.of(context).colorScheme.primary,
      ),
      _Slide(
        icon: Icons.theater_comedy_rounded,
        title: 'The Narrator',
        description:
            'One player hosts the game as the Narrator. They do not play, but guide the story, manage the phases, and decide the fate of the village.',
        color: Colors.blueAccent,
      ),
      const _Slide(
        icon: Icons.nightlight_round,
        title: 'Night Phase',
        description:
            'The village sleeps. The Mafia wake up to choose their victim. The Doctor saves someone. The Detective investigates a player.',
        color: Colors.deepPurpleAccent,
      ),
      const _Slide(
        icon: Icons.wb_sunny_rounded,
        title: 'Day Phase',
        description:
            'The village wakes up. The Narrator reveals who died. Players discuss, debate, and vote to eliminate a suspected Mafia member.',
        color: Colors.orangeAccent,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                  return _buildSlide(slides[index]);
                },
              ),
            ),

            // Pagination dots and Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicator
                  Row(
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == slides.length - 1) {
                        _onDone();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: _currentPage == slides.length - 1
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade900,
                      foregroundColor: _currentPage == slides.length - 1
                          ? Colors.black
                          : Colors.white,
                    ),
                    child: Text(
                      _currentPage == slides.length - 1 ? "GET STARTED" : "NEXT",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_Slide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(slide.icon, size: 100, color: slide.color),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            slide.description,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60), // Push up slightly from center
        ],
      ),
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
