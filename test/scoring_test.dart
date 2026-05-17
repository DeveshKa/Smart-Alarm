import 'package:flutter_test/flutter_test.dart';
import 'package:smart_alarm/src/dictionary.dart';

void main() {
  group('Word Shooting Game Scoring Tests', () {
    test('Verify Fibonacci scoring logic', () {
      // 2-letter word -> 2 points
      expect(getScore(2), equals(2));
      
      // 3-letter word -> 3 points
      expect(getScore(3), equals(3));
      
      // 4-letter word -> 3 + 2 = 5 points
      expect(getScore(4), equals(5));
      
      // 5-letter word -> 5 + 3 = 8 points
      expect(getScore(5), equals(8));
      
      // 6-letter word -> 8 + 5 = 13 points
      expect(getScore(6), equals(13));
      
      // 7-letter word -> 13 + 8 = 21 points
      expect(getScore(7), equals(21));
      
      // 8-letter word -> 21 + 13 = 34 points
      expect(getScore(8), equals(34));
      
      // Less than 2 letters should give 0 points
      expect(getScore(1), equals(0));
      expect(getScore(0), equals(0));
    });

    test('Verify Dictionary contains new common words', () {
      // Common words that are now included in the expanded dictionary
      expect(dictionary.contains('about'), isTrue);
      expect(dictionary.contains('search'), isTrue);
      expect(dictionary.contains('business'), isTrue);
      expect(dictionary.contains('hand'), isTrue);
      expect(dictionary.contains('bit'), isTrue);
      expect(dictionary.contains('and'), isTrue);
      
      // Extremely long or invalid non-existent words
      expect(dictionary.contains('xyzabcqwe'), isFalse);
    });
  });
}
