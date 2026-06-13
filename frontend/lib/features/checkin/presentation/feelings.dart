/// Shared feelings/mood constants used by the check-in form and the trip
/// timeline page. Adding or renaming a feeling here automatically propagates
/// to every rendering site.
const kFeelings = <({String value, String emoji, String label})>[
  (value: 'amazing', emoji: '🤩', label: 'Amazing'),
  (value: 'love', emoji: '😍', label: 'Loved it'),
  (value: 'good', emoji: '😊', label: 'Good'),
  (value: 'neutral', emoji: '😐', label: 'Okay'),
  (value: 'sad', emoji: '😔', label: 'Tough'),
];

/// Returns the emoji for a mood value, or an empty string when unrecognised.
String moodEmoji(String? mood) {
  if (mood == null) return '';
  for (final f in kFeelings) {
    if (f.value == mood) return f.emoji;
  }
  return '';
}

/// Returns the label for a mood value, or an empty string when unrecognised.
String moodLabel(String? mood) {
  if (mood == null) return '';
  for (final f in kFeelings) {
    if (f.value == mood) return f.label;
  }
  return '';
}
