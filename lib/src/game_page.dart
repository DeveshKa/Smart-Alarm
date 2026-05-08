import 'package:flutter/material.dart';
import 'dart:math';
import 'trajectory_painter.dart';
import 'dictionary.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<String> availableBalls = [];
  List<String> shotBalls = [];
  int score = 0;
  Offset? trajectoryStart;
  Offset? trajectoryEnd;
  bool isAiming = false;

  @override
  void initState() {
    super.initState();
    _generateBalls();
  }

  void _generateBalls() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    availableBalls = List.generate(10, (_) => letters[random.nextInt(letters.length)]);
  }

  void _shootBall(String letter, Offset position) {
    setState(() {
      availableBalls.remove(letter);
      shotBalls.add(letter);
      _checkForWord();
      if (availableBalls.isEmpty) {
        _generateBalls();
      }
    });
  }

  void _checkForWord() {
    for (int len = 6; len >= 2; len--) {
      if (shotBalls.length >= len) {
        final word = shotBalls.sublist(shotBalls.length - len).join().toLowerCase();
        if (dictionary.contains(word)) {
          setState(() {
            score += getScore(len);
            shotBalls.removeRange(shotBalls.length - len, shotBalls.length);
          });
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Shooting Game'),
      ),
      body: Row(
        children: [
          // Side panel with available balls
          Container(
            width: 100,
            color: Colors.grey[200],
            child: Column(
              children: [
                const Text('Available Balls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableBalls.length,
                    itemBuilder: (context, index) {
                      return Draggable<String>(
                        data: availableBalls[index],
                        feedback: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue,
                          child: Text(availableBalls[index], style: const TextStyle(color: Colors.white, fontSize: 20)),
                        ),
                        childWhenDragging: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey,
                          child: Text(availableBalls[index], style: const TextStyle(color: Colors.white, fontSize: 20)),
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue,
                          child: Text(availableBalls[index], style: const TextStyle(color: Colors.white, fontSize: 20)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Play area
          Expanded(
            child: Column(
              children: [
                Text('Score: $score', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Expanded(
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        trajectoryStart = details.localPosition;
                        isAiming = true;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        trajectoryEnd = details.localPosition;
                      });
                    },
                    onPanEnd: (details) {
                      if (trajectoryStart != null && trajectoryEnd != null && availableBalls.isNotEmpty) {
                        _shootBall(availableBalls.first, trajectoryEnd!);
                      }
                      setState(() {
                        trajectoryStart = null;
                        trajectoryEnd = null;
                        isAiming = false;
                      });
                    },
                    child: Container(
                      color: Colors.white,
                      child: Stack(
                        children: [
                          // Shot balls
                          ...shotBalls.asMap().entries.map((entry) {
                            final index = entry.key;
                            final letter = entry.value;
                            final x = 50.0 + index * 60.0;
                            final y = 200.0;
                            return Positioned(
                              left: x - 25,
                              top: y - 25,
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.green,
                                child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 20)),
                              ),
                            );
                          }),
                          // Trajectory
                          if (isAiming && trajectoryStart != null && trajectoryEnd != null)
                            CustomPaint(
                              painter: TrajectoryPainter(
                                start: trajectoryStart!,
                                end: trajectoryEnd!,
                              ),
                              size: Size.infinite,
                            ),
                        ],
                      ),
                    ),
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