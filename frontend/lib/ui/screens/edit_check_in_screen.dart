import 'package:flutter/material.dart';
import 'check_in_screen.dart';

/// Edit check-in screen — identical layout to CheckInScreen
/// with editMode = true. Existing media is pre-loaded,
/// Save changes button replaces Check in.
class EditCheckInScreen extends StatelessWidget {
  const EditCheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CheckInScreen(editMode: true);
  }
}
