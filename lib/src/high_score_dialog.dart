import 'package:flutter/material.dart';
import 'dart:math';

class HighScoreDialog extends StatefulWidget {
  final int currentScore;
  final List<int> topScores;
  final VoidCallback onPlayAgain;

  const HighScoreDialog({
    super.key,
    required this.currentScore,
    required this.topScores,
    required this.onPlayAgain,
  });

  @override
  State<HighScoreDialog> createState() => _HighScoreDialogState();
}

class _HighScoreDialogState extends State<HighScoreDialog>
    with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late AnimationController _scoresController;
  late AnimationController _confettiController;
  late List<AnimationController> _scoreItemControllers;
  List<_ConfettiParticle> _confettiParticles = [];

  late Animation<double> _dialogScale;
  late Animation<double> _dialogOpacity;

  bool _isNewHighScore = false;
  int _highScoreRank = -1;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkIfNewHighScore();
    _generateConfetti();
  }

  void _setupAnimations() {
    _dialogController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scoresController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Scale animation for dialog
    _dialogScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dialogController, curve: Curves.elasticOut),
    );

    // Opacity animation for dialog
    _dialogOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dialogController, curve: Curves.easeIn),
    );

    // Individual score animations
    _scoreItemControllers = List.generate(
      widget.topScores.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    // Stagger the animations
    _dialogController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scoresController.forward();
      for (int i = 0; i < _scoreItemControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (mounted) _scoreItemControllers[i].forward();
        });
      }
    });
  }

  void _checkIfNewHighScore() {
    final topScores = widget.topScores;
    if (topScores.contains(widget.currentScore)) {
      _isNewHighScore = true;
      _highScoreRank = topScores.indexOf(widget.currentScore) + 1;
    }
  }

  void _generateConfetti() {
    final random = Random();
    _confettiParticles = List.generate(60, (_) {
      return _ConfettiParticle(
        base: Offset(random.nextDouble(), random.nextDouble()),
        direction: Offset(
            random.nextDouble() * 2 - 1, random.nextDouble() * 0.5 - 0.25),
        color: _confettiColor(random),
        speed: 40 + random.nextDouble() * 100,
        radius: 2 + random.nextDouble() * 3,
      );
    });
  }

  Color _confettiColor(Random random) {
    const palette = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
    ];
    return palette[random.nextInt(palette.length)];
  }

  @override
  void dispose() {
    _dialogController.dispose();
    _scoresController.dispose();
    _confettiController.dispose();
    for (final controller in _scoreItemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _dialogScale,
        child: FadeTransition(
          opacity: _dialogOpacity,
          child: Stack(
            children: [
              // Confetti background
              if (_isNewHighScore)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _ConfettiPainter(
                            particles: _confettiParticles,
                            progress: _confettiController.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Main dialog content
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isNewHighScore
                        ? [
                            Colors.amber.shade700,
                            Colors.amber.shade400,
                            Colors.orange.shade500,
                          ]
                        : [
                            Colors.blue.shade600,
                            Colors.blue.shade400,
                            Colors.cyan.shade300,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [Colors.white, Colors.yellow.shade100],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'GAME OVER',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Current Score
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Column(
                          children: [
                            const Text(
                              'Your Score This Game',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.currentScore}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black26,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            if (_isNewHighScore) ...[
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade400,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'NEW #$_highScoreRank HIGH SCORE!',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.amber,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Top 5 Scores Header
                      const Text(
                        'Top 5 High Scores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Scores List
                      ...List.generate(widget.topScores.length, (index) {
                        final score = widget.topScores[index];
                        final isCurrentScore =
                            score == widget.currentScore && _isNewHighScore;

                        return FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            _scoreItemControllers[index],
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-1, 0),
                              end: Offset.zero,
                            ).animate(_scoreItemControllers[index]),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildScoreCard(
                                rank: index + 1,
                                score: score,
                                isCurrentScore: isCurrentScore,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      // Play Again Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onPlayAgain,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                          ),
                          child: const Text(
                            'PLAY AGAIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard({
    required int rank,
    required int score,
    required bool isCurrentScore,
  }) {
    final medals = ['🥇', '🥈', '🥉', '⭐', '⭐'];
    final medal = rank <= 3 ? medals[rank - 1] : medals[3 + (rank - 4)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrentScore
              ? [Colors.yellow.shade700, Colors.yellow.shade600]
              : [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentScore ? Colors.yellow.shade300 : Colors.white30,
          width: isCurrentScore ? 3 : 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                medal,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Position',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isCurrentScore ? Colors.white : Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black26,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  final Offset base;
  final Offset direction;
  final Color color;
  final double speed;
  final double radius;

  _ConfettiParticle({
    required this.base,
    required this.direction,
    required this.color,
    required this.speed,
    required this.radius,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    for (final particle in particles) {
      final origin =
          Offset(particle.base.dx * size.width, particle.base.dy * size.height);
      final offset = origin + particle.direction * particle.speed * progress;
      final opacity = (1.0 - (progress - 0.7).abs()).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particle.color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, particle.radius * (1 + progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles;
  }
}
