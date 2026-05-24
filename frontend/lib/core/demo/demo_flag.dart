import 'package:flutter_riverpod/flutter_riverpod.dart';

// Runtime toggle — true = mock data, false = real backend.
// Change in Profile page without rebuilding.
final demoModeProvider = StateProvider<bool>((ref) => false);

// Compile-time constants (kept for backward compat with existing code).
const bool kDemoMode = false;
const bool kSkipAuth = false;
const bool kStubAi = true;
