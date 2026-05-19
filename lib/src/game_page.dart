import 'dart:math';

import 'package:flutter/material.dart';
import 'trajectory_painter.dart';
import 'dictionary.dart';
import 'image_utils.dart';
import 'high_score_manager.dart';
import 'high_score_dialog.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  List<String> availableBalls = [];
  // 10x10 matrix: row * 10 + col
  List<String?> placedLetters = List.filled(100, null);
  int score = 0;
  int roundsLeft = 100;
  int selectedBallIndex = -1;
  bool isAiming = false;
  bool isAnimating = false;
  String lastWordMessage = 'Select a ball and drag to shoot.';
  Offset? aimTarget;
  late final AnimationController _shotController;
  Animation<Offset>? _shotAnimation;
  String? _movingLetter;
  int? _landingRow;
  int? _landingCol;
  Size? _playSize;
  int? _targetColumn;
  bool _showConfetti = false;
  bool _doubleConfetti = false;
  late final AnimationController _confettiController;
  List<_ConfettiParticle> _confettiParticles = [];
  Set<String> madeWords = {};
  Set<String> shownDuplicateDialog = {};

  // Background wallpaper image path
  String? _backgroundImage;

  // High score management
  late HighScoreManager _highScoreManager;
  int _highestScore = 0;
  bool _gameOverDialogShown = false;

  @override
  void initState() {
    super.initState();
    _highScoreManager = HighScoreManager();
    _loadHighestScore();

    _shotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finishShot();
        }
      });

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _showConfetti = false;
          });
        }
      });

    _backgroundImage = ImageUtils.getRandomBackgroundImage();
    _generateBalls();
  }

  void _loadHighestScore() async {
    final highest = await _highScoreManager.getHighestScore();
    setState(() {
      _highestScore = highest;
    });
  }

  @override
  void dispose() {
    _shotController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  bool get gameOver => roundsLeft <= 0 && !isAnimating;

  bool _isAcceptedWord(String word) {
    return dictionary.contains(word);
  }

  void _checkGameOverAndShowDialog() {
    if (gameOver && !_gameOverDialogShown) {
      _gameOverDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showGameOverDialog();
        }
      });
    }
  }

  String _getRandomLetter() {
    final weightedLetters = <String>[];
    // Very common letters (x4)
    const veryCommon = [
      'E',
      'T',
      'A',
      'O',
      'I',
      'N',
      'S',
      'H',
      'R',
      'D',
      'L',
      'C',
      'U',
      'M'
    ];
    for (final letter in veryCommon) {
      weightedLetters.addAll(List.filled(4, letter));
    }
    // Frequent letters (x2)
    const frequent = ['W', 'F', 'G', 'Y', 'P', 'B', 'V', 'K', 'J'];
    for (final letter in frequent) {
      weightedLetters.addAll(List.filled(2, letter));
    }
    // Less used (x1)
    const lessUsed = ['X', 'Q', 'Z'];
    weightedLetters.addAll(lessUsed);
    // Double vowels
    const vowels = ['A', 'E', 'I', 'O', 'U'];
    for (final vowel in vowels) {
      weightedLetters.addAll(List.filled(4, vowel));
    }
    final random = Random();
    return weightedLetters[random.nextInt(weightedLetters.length)];
  }

  void _generateBalls() {
    availableBalls = List.generate(12, (_) => _getRandomLetter());
  }

  void _resetGame() {
    setState(() {
      score = 0;
      roundsLeft = 100;
      placedLetters = List.filled(100, null);
      selectedBallIndex = -1;
      isAiming = false;
      aimTarget = null;
      _movingLetter = null;
      _shotAnimation = null;
      _targetColumn = null;
      _showConfetti = false;
      _doubleConfetti = false;
      _confettiParticles = [];
      madeWords = {};
      shownDuplicateDialog = {};
      lastWordMessage = 'Select a ball and drag to shoot.';
      _backgroundImage = ImageUtils.getRandomBackgroundImage();
      _gameOverDialogShown = false;
      _generateBalls();
    });
  }

  void _showGameOverDialog() async {
    // Save the score
    await _highScoreManager.addScore(score);

    // Get top 5 scores
    final topScores = await _highScoreManager.getTopScores();

    // Load highest score for display
    _loadHighestScore();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => HighScoreDialog(
        currentScore: score,
        topScores: topScores,
        onPlayAgain: () {
          Navigator.pop(context);
          _resetGame();
        },
      ),
    );
  }

  void _selectBall(int index) {
    if (isAnimating || gameOver) return;
    setState(() {
      selectedBallIndex = index;
      lastWordMessage =
          'Aiming ${availableBalls[index]} - drag on the field to shoot.';
    });
  }

  void _startAiming(Offset position, Size size) {
    if (selectedBallIndex < 0 || isAnimating || gameOver) {
      return;
    }
    setState(() {
      isAiming = true;
      _playSize = size;
      _targetColumn = _computeTargetColumn(position, size);
      aimTarget = _computeAimTarget(_targetColumn!, size);
    });
  }

  void _updateAiming(Offset position, Size size) {
    if (!isAiming || isAnimating || gameOver) {
      return;
    }
    setState(() {
      _playSize = size;
      _targetColumn = _computeTargetColumn(position, size);
      aimTarget = _computeAimTarget(_targetColumn!, size);
    });
  }

  void _shootSelectedBall() {
    if (selectedBallIndex < 0 || aimTarget == null || isAnimating || gameOver) {
      return;
    }

    if (_playSize == null || _targetColumn == null) {
      return;
    }

    final result = _chooseLandingPosition(_targetColumn!);

    if (result == null) {
      setState(() {
        lastWordMessage = 'Cannot shoot further in that column!';
      });
      return;
    }

    final letter = availableBalls.removeAt(selectedBallIndex);
    availableBalls.add(_getRandomLetter());
    selectedBallIndex = -1;
    isAnimating = true;
    setState(() {
      roundsLeft = max(0, roundsLeft - 1);
      lastWordMessage = 'Shooting $letter...';
      _movingLetter = letter;
      _landingRow = result['row'] as int;
      _landingCol = result['col'] as int;
      aimTarget = _slotCenter(_landingRow!, _landingCol!, _playSize!);
    });

    final startPosition = Offset(aimTarget!.dx, 0.0);
    _shotAnimation = Tween<Offset>(begin: startPosition, end: aimTarget!)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_shotController);

    _shotController.forward(from: 0.0);
  }

  void _finishShot() {
    setState(() {
      if (_movingLetter != null && _landingRow != null && _landingCol != null) {
        placedLetters[_landingRow! * 10 + _landingCol!] = _movingLetter;
        _checkForWord();
      }
      isAnimating = false;
      isAiming = false;
      aimTarget = null;
      _shotAnimation = null;
      _movingLetter = null;
      _landingRow = null;
      _landingCol = null;
      if (availableBalls.isEmpty && !gameOver) {
        _generateBalls();
      }
    });
    _checkGameOverAndShowDialog();
  }

  void _checkForWord() {
    String message = 'Keep shooting to form a valid word.';

    // Check horizontal words first
    for (int row = 0; row < 10; row++) {
      for (int len = 10; len >= 2; len--) {
        for (int start = 0; start <= 10 - len; start++) {
          final slice = List<String?>.generate(
              len, (index) => placedLetters[row * 10 + start + index]);
          if (slice.any((letter) => letter == null)) continue;
          final word = slice.join().toLowerCase();
          if (_isAcceptedWord(word)) {
            if (madeWords.contains(word)) {
              if (!shownDuplicateDialog.contains(word)) {
                shownDuplicateDialog.add(word);
                _showAlreadyMadeDialog(word);
              }
              return;
            }
            final points = getScore(len);
            score += points;
            madeWords.add(word);
            for (int index = 0; index < len; index++) {
              placedLetters[row * 10 + start + index] = null;
            }
            message = 'Great! "$word" +$points points.';
            _triggerConfetti(word.length);
            lastWordMessage = message;
            return;
          }
        }
      }
    }

    // Check vertical words
    for (int col = 0; col < 10; col++) {
      for (int len = 10; len >= 2; len--) {
        for (int start = 0; start <= 10 - len; start++) {
          final slice = List<String?>.generate(
              len, (index) => placedLetters[(start + index) * 10 + col]);
          if (slice.any((letter) => letter == null)) continue;
          final word = slice.join().toLowerCase();
          if (_isAcceptedWord(word)) {
            if (madeWords.contains(word)) {
              if (!shownDuplicateDialog.contains(word)) {
                shownDuplicateDialog.add(word);
                _showAlreadyMadeDialog(word);
              }
              return;
            }
            final points = getScore(len);
            score += points;
            madeWords.add(word);
            for (int index = 0; index < len; index++) {
              placedLetters[(start + index) * 10 + col] = null;
            }
            message = 'Great! "$word" +$points points.';
            _triggerConfetti(word.length);
            lastWordMessage = message;
            return;
          }
        }
      }
    }

    final visibleLetters = placedLetters.map((letter) => letter ?? '_').join();
    if (visibleLetters.replaceAll('_', '').isNotEmpty) {
      message = 'Current: ${visibleLetters.toUpperCase()}';
    }

    lastWordMessage = message;
  }

  void _triggerConfetti(int wordLength) {
    final random = Random();
    _doubleConfetti = wordLength > 4;
    final particleCount = _doubleConfetti ? 60 : 30;
    _confettiParticles = List.generate(particleCount, (_) {
      return _ConfettiParticle(
        base: Offset(random.nextDouble(), random.nextDouble()),
        direction:
            Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1),
        color: _confettiColor(random),
        speed: 40 + random.nextDouble() * 120,
        radius: 3 + random.nextDouble() * 4,
      );
    });
    _showConfetti = true;
    _confettiController.forward(from: 0.0);
  }

  void _showAlreadyMadeDialog(String word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Word Already Made!'),
        content: Text(
          'You\'ve already made the word "$word" earlier.\n\nTry making a different word!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  Color _ballColor(String letter) {
    const colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
    ];
    final index = (letter.codeUnitAt(0) - 65) % colors.length;
    return colors[index];
  }

  Offset _launcherCenter(Size size) {
    return Offset(size.width / 2, size.height - 60);
  }

  int _computeTargetColumn(Offset pointer, Size size) {
    final boxWidth = size.width / 10;
    return ((pointer.dx) / boxWidth).floor().clamp(0, 9);
  }

  Offset _computeAimTarget(int column, Size size) {
    final boxWidth = size.width / 10;
    final boxHeight = (size.height - 16 - 60) / 10; // Playable height / 10 rows

    const targetRow = 0; // Aim towards top row
    final targetX = (column + 0.5) * boxWidth;
    final targetY = 16 + (targetRow + 0.5) * boxHeight;

    return Offset(targetX, targetY);
  }

  Map<String, int>? _chooseLandingPosition(int column) {
    if (column < 0 || column > 9) {
      return null;
    }

    for (int row = 0; row < 10; row++) {
      final index = row * 10 + column;
      if (placedLetters[index] == null) {
        return {'row': row, 'col': column};
      }
    }

    // Column is full
    return null;
  }

  Offset _slotCenter(int row, int col, Size size) {
    final boxWidth = size.width / 10;
    final boxHeight = (size.height - 16 - 60) / 10;

    final x = (col + 0.5) * boxWidth;
    final y = 16 + (row + 0.5) * boxHeight;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Shooting Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 120,
            color: Colors.grey[200],
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balls',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: min(12, availableBalls.length),
                    itemBuilder: (context, index) {
                      final letter = availableBalls[index];
                      final isSelected = index == selectedBallIndex;

                      return GestureDetector(
                        onTap: () => _selectBall(index),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Colors.orange,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue,
                            child: Text(
                              letter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text('Score: $score',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Rounds: $roundsLeft',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                // Highest Score Display
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.orange.shade500],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🏆',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Best Score',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_highestScore',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black26,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: _resetGame, child: const Text('Reset')),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Status: ${gameOver ? 'Game Over' : lastWordMessage}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                          'Placed: ${placedLetters.where((l) => l != null).join()}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      const Text('Words made:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 96),
                        child: madeWords.isEmpty
                            ? const Text('None yet',
                                style: TextStyle(fontSize: 14))
                            : SingleChildScrollView(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: madeWords
                                      .map((word) => Chip(
                                            label: Text(word.toUpperCase()),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                          ))
                                      .toList(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final playSize =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      final launcher = _launcherCenter(playSize);
                      return GestureDetector(
                        onPanStart: (details) {
                          _startAiming(details.localPosition, playSize);
                        },
                        onPanUpdate: (details) {
                          _updateAiming(details.localPosition, playSize);
                        },
                        onPanEnd: (details) {
                          _shootSelectedBall();
                          setState(() {
                            isAiming = false;
                            aimTarget = null;
                          });
                        },
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            image: _backgroundImage != null
                                ? DecorationImage(
                                    image: AssetImage(_backgroundImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 4),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: launcher.dx - 34,
                                top: launcher.dy - 34,
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.deepPurple, width: 4),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: launcher.dx - 2,
                                top: launcher.dy - 8,
                                child: Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              if (isAiming && _targetColumn != null)
                                Positioned(
                                  left: _targetColumn! *
                                      (constraints.maxWidth / 10),
                                  top: 16,
                                  width: constraints.maxWidth / 10,
                                  bottom: 60,
                                  child: Container(
                                    color:
                                        const Color.fromARGB(20, 33, 150, 243),
                                  ),
                                ),
                              if (isAiming && aimTarget != null)
                                CustomPaint(
                                  painter: TrajectoryPainter(
                                    start: launcher,
                                    end: aimTarget!,
                                  ),
                                  size: Size.infinite,
                                ),
                              if (_showConfetti)
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
                                          child: const SizedBox.expand(),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: 0,
                                top: 16,
                                right: 0,
                                bottom: 60,
                                child: Column(
                                  children: List.generate(10, (row) {
                                    return Expanded(
                                      child: Row(
                                        children: List.generate(10, (col) {
                                          final index = row * 10 + col;
                                          final letter = placedLetters[index];
                                          final boxWidth =
                                              constraints.maxWidth / 10;
                                          final boxHeight =
                                              (constraints.maxHeight -
                                                      16 -
                                                      60) /
                                                  10;
                                          final ballSize = max(0,
                                                  min(boxWidth, boxHeight) - 16)
                                              .toDouble();

                                          return Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 1,
                                                ),
                                              ),
                                              child: letter != null
                                                  ? Center(
                                                      child: CircleAvatar(
                                                        radius: ballSize / 2,
                                                        backgroundColor:
                                                            _ballColor(letter),
                                                        child: Text(letter,
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                          );
                                        }),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              if (_shotAnimation != null &&
                                  _movingLetter != null)
                                AnimatedBuilder(
                                  animation: _shotAnimation!,
                                  builder: (context, child) {
                                    final position = _shotAnimation!.value;
                                    return Positioned(
                                      left: position.dx - 20,
                                      top: position.dy - 20,
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor:
                                            _ballColor(_movingLetter!),
                                        child: Text(_movingLetter!,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    );
                                  },
                                ),
                              if (gameOver)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particle.color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, particle.radius * (1 + progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles;
  }
}
