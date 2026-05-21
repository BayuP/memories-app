import 'package:flutter_riverpod/flutter_riverpod.dart';

// Runtime toggle — true = mock data, false = real backend.
// Change in Profile page without rebuilding.
final demoModeProvider = StateProvider<bool>((ref) => true);
