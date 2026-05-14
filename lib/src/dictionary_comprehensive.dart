// ignore_for_file: equal_elements_in_set
// Accepted word dictionary for the game.
// This dictionary includes only nouns, verbs, adjectives, adverbs, conjunctions,
// interjections, and pronouns. Prepositions, articles, determiners, and other
// excluded parts of speech are intentionally omitted.

final Set<String> acceptedDictionary = {
  // Conjunctions
  'and', 'but', 'or', 'yet', 'so', 'for', 'nor', 'because', 'although', 'while', 'unless', 'if', 'as', 'since', 'whether',

  // Interjections
  'ah', 'aw', 'eh', 'ha', 'hey', 'hi', 'ho', 'oh', 'oi', 'wow', 'yo', 'yay',

  // Pronouns
  'we', 'you', 'he', 'she', 'it', 'they', 'them', 'us', 'our', 'your', 'his', 'her', 'hers', 'ours', 'mine', 'theirs',
  'who', 'whom', 'whose', 'this', 'that', 'these', 'those', 'all', 'some', 'every', 'another', 'which',

  // Nouns
  'cat', 'dog', 'game', 'house', 'score', 'time', 'word', 'ball', 'tree', 'rain', 'fire', 'water', 'light', 'night',
  'morning', 'city', 'music', 'ocean', 'star', 'dream', 'friend', 'child', 'car', 'book', 'party', 'field', 'class',
  'family', 'school', 'teacher', 'country', 'story', 'garden', 'river', 'world', 'forest', 'market', 'window',
  'summer', 'winter', 'artist', 'worker', 'movie', 'season', 'people', 'voice', 'heart', 'memory', 'idea', 'chance',
  'reason', 'nature', 'signal', 'course', 'matter', 'effect', 'energy', 'travel', 'method', 'vision', 'system',
  'planet', 'rocket', 'model', 'bridge', 'heart', 'truth', 'space', 'planet', 'forest', 'journal', 'camera', 'garden',
  'mirror', 'planet', 'hobby', 'doctor', 'teacher', 'leader', 'master', 'father', 'mother', 'sister', 'brother',

  // Verbs
  'run', 'jump', 'play', 'make', 'take', 'give', 'have', 'be', 'do', 'say', 'see', 'know', 'think', 'feel', 'want',
  'need', 'work', 'call', 'keep', 'seem', 'help', 'start', 'stop', 'move', 'look', 'watch', 'write', 'speak',
  'listen', 'smile', 'laugh', 'dream', 'grow', 'learn', 'build', 'change', 'follow', 'open', 'close', 'reach',
  'remember', 'discover', 'create', 'answer', 'travel', 'wonder', 'share', 'support', 'choose', 'accept', 'honor',
  'charge', 'treat', 'return', 'remain', 'appear', 'serve', 'perform', 'explore', 'improve', 'protect', 'invite',
  'teach', 'offer', 'search', 'remain', 'listen', 'deliver', 'decide', 'reduce', 'refuse', 'reply', 'report',
  'replace', 'repair', 'respond', 'return', 'review', 'reward', 'rise', 'carry', 'build', 'charge', 'charge',

  // Adjectives
  'good', 'great', 'best', 'new', 'old', 'young', 'happy', 'sad', 'quick', 'slow', 'sharp', 'bright', 'dark',
  'strong', 'sweet', 'clean', 'clear', 'loud', 'quiet', 'brave', 'calm', 'kind', 'crazy', 'funny', 'proud',
  'fresh', 'smart', 'safe', 'natural', 'simple', 'special', 'early', 'late', 'ready', 'basic', 'final', 'local',
  'common', 'modern', 'serious', 'silent', 'perfect', 'gentle', 'honest', 'happy', 'famous', 'busy', 'eager',

  // Adverbs
  'very', 'well', 'always', 'never', 'often', 'quickly', 'slowly', 'early', 'late', 'soon', 'really', 'simply',
  'nearly', 'rarely', 'almost', 'finally', 'suddenly', 'quietly', 'softly', 'loudly', 'bravely', 'easily', 'mostly',
  'usually', 'truly', 'neatly', 'wildly', 'briefly', 'firmly', 'fully', 'deeply', 'gently', 'honestly',
  'patiently', 'properly',
};
