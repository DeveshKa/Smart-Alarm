import 'package:shared_preferences/shared_preferences.dart';

class HighScoreManager {
  static const String _key = 'high_scores';
  static const int _maxScores = 5;

  Future<void> addScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = await getTopScores();

    // Add new score to the list
    scores.add(score);

    // Sort in descending order (highest first)
    scores.sort((a, b) => b.compareTo(a));

    // Keep only top 5
    if (scores.length > _maxScores) {
      scores.removeRange(_maxScores, scores.length);
    }

    // Save to preferences
    await prefs.setStringList(_key, scores.map((s) => s.toString()).toList());
  }

  Future<List<int>> getTopScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoreStrings = prefs.getStringList(_key) ?? [];
    return scoreStrings.map((s) => int.tryParse(s) ?? 0).toList();
  }

  Future<int> getHighestScore() async {
    final scores = await getTopScores();
    return scores.isEmpty ? 0 : scores.first;
  }

  Future<void> clearScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<bool> isHighScore(int score) async {
    final topScores = await getTopScores();

    // If we have less than 5 scores, it's a high score
    if (topScores.length < _maxScores) {
      return true;
    }

    // Otherwise, check if it's better than the worst in the top 5
    return score > topScores.last;
  }
}
