import 'dart:math';

import 'package:flutter/material.dart';
import 'trajectory_painter.dart';
import 'dictionary.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  List<String> availableBalls = [];
  List<String?> placedLetters = List.filled(10, null);
  int score = 0;
  int roundsLeft = 15;
  int selectedBallIndex = -1;
  bool isAiming = false;
  bool isAnimating = false;
  String lastWordMessage = 'Select a ball and drag to shoot.';
  Offset? aimTarget;
  Offset _launcherPosition = Offset.zero;
  late final AnimationController _shotController;
  Animation<Offset>? _shotAnimation;
  String? _movingLetter;
  Size? _playSize;

  @override
  void initState() {
    super.initState();
    _shotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finishShot();
        }
      });

    _generateBalls();
  }

  @override
  void dispose() {
    _shotController.dispose();
    super.dispose();
  }

  bool get gameOver => roundsLeft <= 0 && !isAnimating;

  void _generateBalls() {
    final weightedLetters = <String>[];
    // Very common letters (x4)
    const veryCommon = ['E', 'T', 'A', 'O', 'I', 'N', 'S', 'H', 'R', 'D', 'L', 'C', 'U', 'M'];
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
    availableBalls = List.generate(10, (_) => weightedLetters[random.nextInt(weightedLetters.length)]);
  }

  void _resetGame() {
    setState(() {
      score = 0;
      roundsLeft = 15;
      placedLetters = List.filled(10, null);
      selectedBallIndex = -1;
      isAiming = false;
      aimTarget = null;
      _movingLetter = null;
      _shotAnimation = null;
      lastWordMessage = 'Select a ball and drag to shoot.';
      _generateBalls();
    });
  }

  void _selectBall(int index) {
    if (isAnimating || gameOver) return;
    setState(() {
      selectedBallIndex = index;
      lastWordMessage = 'Aiming ${availableBalls[index]} - drag on the field to shoot.';
    });
  }

  void _startAiming(Offset position, Size size) {
    if (selectedBallIndex < 0 || isAnimating || gameOver) return;
    setState(() {
      isAiming = true;
      _launcherPosition = _launcherCenter(size);
      _playSize = size;
      aimTarget = _computeAimTarget(position, size);
    });
  }

  void _updateAiming(Offset position, Size size) {
    if (!isAiming || isAnimating || gameOver) return;
    setState(() {
      _launcherPosition = _launcherCenter(size);
      _playSize = size;
      aimTarget = _computeAimTarget(position, size);
    });
  }

  void _shootSelectedBall() {
    if (selectedBallIndex < 0 || aimTarget == null || isAnimating || gameOver) return;

    final letter = availableBalls.removeAt(selectedBallIndex);
    selectedBallIndex = -1;
    isAnimating = true;
    setState(() {
      roundsLeft = max(0, roundsLeft - 1);
      lastWordMessage = 'Shooting $letter...';
    });

    _movingLetter = letter;
    _shotAnimation = Tween<Offset>(begin: _launcherPosition, end: aimTarget!)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_shotController);

    _shotController.forward(from: 0.0);
  }

  void _finishShot() {
    setState(() {
      if (_movingLetter != null && aimTarget != null && _playSize != null) {
        final boxWidth = _playSize!.width / 10;
        final boxIndex = ((aimTarget!.dx / boxWidth) - 0.5).round().clamp(0, 9);
        if (placedLetters[boxIndex] == null) {
          placedLetters[boxIndex] = _movingLetter;
          _checkForWord();
        }
      }
      isAnimating = false;
      isAiming = false;
      aimTarget = null;
      _shotAnimation = null;
      _movingLetter = null;
      if (availableBalls.isEmpty && !gameOver) {
        _generateBalls();
      }
    });
  }

  void _checkForWord() {
    final currentLetters = placedLetters.where((l) => l != null).map((l) => l!).toList();
    String message = 'Keep shooting to form a valid word.';
    for (int len = 6; len >= 2; len--) {
      if (currentLetters.length >= len) {
        final word = currentLetters.sublist(currentLetters.length - len).join().toLowerCase();
        if (dictionary.contains(word)) {
          final points = getScore(len);
          score += points;
          // Remove the last len letters
          for (int i = placedLetters.length - 1; i >= 0 && len > 0; i--) {
            if (placedLetters[i] != null) {
              placedLetters[i] = null;
              len--;
            }
          }
          message = 'Great! "$word" +$points points.';
          break;
        }
      }
    }

    if (message.startsWith('Keep')) {
      final current = currentLetters.join();
      if (current.isNotEmpty) {
        message = 'Current letters: ${current.toUpperCase()}';
      }
    }

    setState(() {
      lastWordMessage = message;
    });
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

  Offset _computeAimTarget(Offset pointer, Size size) {
    final boxWidth = size.width / 10;
    final boxIndex = (pointer.dx / boxWidth).floor().clamp(0, 9);
    final targetX = (boxIndex + 0.5) * boxWidth;
    final targetY = 40.0; // Top of the play area
    return Offset(targetX, targetY);
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
                const Text('Available Balls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: availableBalls.length,
                    itemBuilder: (context, index) {
                      final letter = availableBalls[index];
                      final isSelected = index == selectedBallIndex;
                      return GestureDetector(
                        onTap: () => _selectBall(index),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: isSelected ? Colors.orange : Colors.blue,
                          child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text('Score: $score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Rounds: $roundsLeft', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _resetGame, child: const Text('Reset')),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.blue[50],
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${gameOver ? 'Game Over' : lastWordMessage}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Placed: ${placedLetters.where((l) => l != null).join()}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final playSize = Size(constraints.maxWidth, constraints.maxHeight);
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
                          color: Colors.white,
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
                                    border: Border.all(color: Colors.deepPurple, width: 4),
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
                              if (isAiming && aimTarget != null)
                                CustomPaint(
                                  painter: TrajectoryPainter(
                                    start: launcher,
                                    end: aimTarget!,
                                  ),
                                  size: Size.infinite,
                                ),
                              Positioned(
                                left: 0,
                                top: 16,
                                right: 0,
                                child: Row(
                                  children: List.generate(10, (index) {
                                    final letter = placedLetters[index];
                                    return SizedBox(
                                      width: constraints.maxWidth / 10,
                                      height: 50,
                                      child: letter != null
                                          ? Center(
                                              child: CircleAvatar(
                                                radius: (constraints.maxWidth / 10) / 2 - 5,
                                                backgroundColor: _ballColor(letter),
                                                child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    );
                                  }),
                                ),
                              ),
                              if (_shotAnimation != null && _movingLetter != null)
                                AnimatedBuilder(
                                  animation: _shotAnimation!,
                                  builder: (context, child) {
                                    final position = _shotAnimation!.value;
                                    return Positioned(
                                      left: position.dx - 20,
                                      top: position.dy - 20,
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _ballColor(_movingLetter!),
                                        child: Text(_movingLetter!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      ),
                                    );
                                  },
                                ),
                              if (gameOver)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black54,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('GAME OVER', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 16),
                                          Text('Final Score: $score', style: const TextStyle(color: Colors.white, fontSize: 20)),
                                          const SizedBox(height: 16),
                                          ElevatedButton(onPressed: _resetGame, child: const Text('Play Again')),
                                        ],
                                      ),
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
