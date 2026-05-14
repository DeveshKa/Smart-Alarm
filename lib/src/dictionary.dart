import 'dictionary_comprehensive.dart';

// A curated dictionary alias for the game.
// Only words that belong to accepted parts of speech are included.
final Set<String> dictionary = acceptedDictionary;

int getScore(int length) {
  switch (length) {
    case 2:
      return 1;
    case 3:
      return 2;
    case 4:
      return 3;
    case 5:
      return 5;
    case 6:
      return 8;
    case 7:
      return 12;
    case 8:
      return 16;
    case 9:
      return 20;
    case 10:
      return 25;
    default:
      return 0;
  }
}
