# SpeechKit

Headless speech recognition and pronunciation evaluation engine for VocabCraft.

## Features
- Real-time audio buffer capture with `AVAudioEngine` and silence detection.
- Speech transcription using Apple's `SFSpeechRecognizer`.
- Phonetic & fuzzy token alignment using Needleman-Wunsch sequence aligner and Levenshtein distance.
- Strictly headless: Zero UI dependencies, fast test execution on macOS and iOS.
