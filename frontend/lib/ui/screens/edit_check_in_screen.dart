import 'package:flutter/material.dart';
import 'check_in_screen.dart';

/// Edit check-in screen — identical layout to CheckInScreen
/// with editMode = true. Existing media is pre-loaded,
/// Save changes button replaces Check in.
class EditCheckInScreen extends StatelessWidget {
  const EditCheckInScreen({
    super.key,
    required this.tripId,
    this.itemId,
    this.kind = 'planned',
  });

  final String tripId;
  final String? itemId;
  final String kind;

  @override
  Widget build(BuildContext context) {
    return CheckInScreen(
      editMode: true,
      tripId: tripId,
      itemId: itemId,
      kind: kind,
    );
  }
}
