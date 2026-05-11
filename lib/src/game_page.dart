import 'dart:math';

import 'package:flutter/material.dart';
import 'trajectory_painter.dart';
import 'dictionary.dart';

enum ShootDirection { up, upLeft, upRight }

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
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
  ShootDirection _shootDirection = ShootDirection.up;

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
    availableBalls = List.generate(
        100, (_) => weightedLetters[random.nextInt(weightedLetters.length)]);
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
      _shootDirection = ShootDirection.up;
      lastWordMessage = 'Select a ball and drag to shoot.';
      _generateBalls();
    });
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
      aimTarget = _computeAimTarget(position, size);
    });
  }

  void _updateAiming(Offset position, Size size) {
    if (!isAiming || isAnimating || gameOver) {
      return;
    }
    setState(() {
      _playSize = size;
      aimTarget = _computeAimTarget(position, size);
    });
  }

  void _shootSelectedBall() {
    if (selectedBallIndex < 0 || aimTarget == null || isAnimating || gameOver) {
      return;
    }

    if (_playSize == null || aimTarget == null) {
      return;
    }

    final boxWidth = _playSize!.width / 10;
    final targetCol = (aimTarget!.dx / boxWidth).floor().clamp(0, 9);

    final result = _chooseLandingPosition(targetCol, _shootDirection);

    if (result == null) {
      setState(() {
        lastWordMessage = 'Cannot shoot further in this direction!';
      });
      return;
    }

    final letter = availableBalls.removeAt(selectedBallIndex);
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
  }

  void _checkForWord() {
    String message = 'Keep shooting to form a valid word.';

    // Check horizontal words
    for (int row = 0; row < 10; row++) {
      for (int len = 6; len >= 2; len--) {
        for (int start = 0; start <= 10 - len; start++) {
          List<String?> slice = [];
          for (int col = start; col < start + len; col++) {
            slice.add(placedLetters[row * 10 + col]);
          }
          if (slice.any((letter) => letter == null)) continue;
          final word = slice.join().toLowerCase();
          if (dictionary.contains(word)) {
            final points = getScore(len);
            score += points;
            for (int col = start; col < start + len; col++) {
              placedLetters[row * 10 + col] = null;
            }
            message = 'Great! "$word" +$points points.';
            setState(() {
              lastWordMessage = message;
            });
            return;
          }
        }
      }
    }

    // Check vertical words
    for (int col = 0; col < 10; col++) {
      for (int len = 6; len >= 2; len--) {
        for (int start = 0; start <= 10 - len; start++) {
          List<String?> slice = [];
          for (int row = start; row < start + len; row++) {
            slice.add(placedLetters[row * 10 + col]);
          }
          if (slice.any((letter) => letter == null)) continue;
          final word = slice.join().toLowerCase();
          if (dictionary.contains(word)) {
            final points = getScore(len);
            score += points;
            for (int row = start; row < start + len; row++) {
              placedLetters[row * 10 + col] = null;
            }
            message = 'Great! "$word" +$points points.';
            setState(() {
              lastWordMessage = message;
            });
            return;
          }
        }
      }
    }

    final visibleLetters = placedLetters.map((letter) => letter ?? '_').join();
    if (visibleLetters.replaceAll('_', '').isNotEmpty) {
      message = 'Current: ${visibleLetters.toUpperCase()}';
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
    _shootDirection = _determineDirection(pointer, size);
    final boxWidth = size.width / 10;
    final boxHeight = (size.height - 16 - 60) / 10; // Playable height / 10 rows

    int targetCol = ((pointer.dx) / boxWidth).floor().clamp(0, 9);
    const targetRow = 0; // Aim towards top row

    final targetX = (targetCol + 0.5) * boxWidth;
    final targetY = 16 + (targetRow + 0.5) * boxHeight;

    return Offset(targetX, targetY);
  }

  ShootDirection _determineDirection(Offset position, Size size) {
    final boxWidth = size.width / 10;
    final launcherX = size.width / 2;

    // Determine direction based on horizontal position relative to launcher
    if (position.dx < launcherX - boxWidth * 2) {
      return ShootDirection.upLeft;
    } else if (position.dx > launcherX + boxWidth * 2) {
      return ShootDirection.upRight;
    }
    return ShootDirection.up;
  }

  Map<String, int>? _chooseLandingPosition(
      int startCol, ShootDirection direction) {
    // Based on direction, search vertically in the appropriate column
    int searchCol = startCol;

    // Adjust column based on direction
    if (direction == ShootDirection.upLeft && startCol > 0) {
      searchCol = startCol - 1;
    } else if (direction == ShootDirection.upRight && startCol < 9) {
      searchCol = startCol + 1;
    }

    // Check boundaries
    if (searchCol < 0 || searchCol > 9) {
      return null;
    }

    // Find first empty slot from top going down in the selected column
    for (int row = 0; row < 10; row++) {
      final index = row * 10 + searchCol;
      if (placedLetters[index] == null) {
        return {'row': row, 'col': searchCol};
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
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              isSelected ? Colors.orange : Colors.blue,
                          child: Text(letter,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
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
                  color: Colors.blue[50],
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

                                          return Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 1,
                                                ),
                                              ),
                                              child: letter != null
                                                  ? Center(
                                                      child: CircleAvatar(
                                                        radius: max(
                                                            0,
                                                            min(boxWidth,
                                                                        boxHeight) /
                                                                    2 -
                                                                8),
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
                                  child: Container(
                                    color: Colors.black54,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('GAME OVER',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 16),
                                          Text('Final Score: $score',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20)),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                              onPressed: _resetGame,
                                              child: const Text('Play Again')),
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
