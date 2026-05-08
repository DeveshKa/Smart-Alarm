# Word Shooting Game

A Flutter game where players shoot letter balls to form words and score points based on Fibonacci sequence.

## Features

- Shoot round balls with alphabet letters
- Dotted fading trajectory path when aiming
- Form words to score points (2 letters: 1 point, 3: 2, 4: 3, 5: 5, 6: 8)
- Side panel with available balls to shoot

## Setup

1. Ensure Flutter SDK is installed. Download from https://flutter.dev/docs/get-started/install
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Game Rules

- Drag and drop balls from the side panel or tap to shoot
- Balls land in a horizontal line
- When consecutive balls form a valid dictionary word, you score points and those balls are removed
- New balls are generated when the available ones are used up

## Files

- `lib/main.dart`: App entry point
- `lib/src/game_page.dart`: Main game logic and UI
- `lib/src/dictionary.dart`: Word list and scoring
- `lib/src/trajectory_painter.dart`: Dotted trajectory drawing