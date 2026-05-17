import 'dictionary_comprehensive.dart';

// A curated dictionary alias for the game.
final Set<String> dictionary = acceptedDictionary;

/// Computes the score of a word of a given length using Fibonacci sequence logic:
/// - 2-letter word: 2 points
/// - 3-letter word: 3 points
/// - 4-letter word: 3 + 2 = 5 points
/// - 5-letter word: 5 + 3 = 8 points
/// - 6-letter word: 8 + 5 = 13 points
/// - N-letter word: score(N-1) + score(N-2) points
int getScore(int length) {
  if (length < 2) return 0;
  if (length == 2) return 2;
  if (length == 3) return 3;

  int prev2 = 2; // Score for length 2
  int prev1 = 3; // Score for length 3
  int current = 3;

  for (int i = 4; i <= length; i++) {
    current = prev1 + prev2;
    prev2 = prev1;
    prev1 = current;
  }
  return current;
}
