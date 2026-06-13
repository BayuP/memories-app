import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memories_app/core/location/geocoding_service.dart';
import 'package:memories_app/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// LocationAutocompleteField
//
// A text field that debounces user input, queries GeocodingService (Nominatim),
// and shows a floating overlay of suggestions below the field. Selecting a
// suggestion fills the field with the shortened label and fires [onSelected]
// with the full PlaceSuggestion (including lat/lng).
//
// Nominatim compliance enforced here:
//   - Debounce: 400 ms between keystrokes.
//   - Minimum 3 characters before a search is issued.
//   - User-Agent is set inside GeocodingService (not the authed app ApiClient).
//
// Manual-edit-without-select behavior:
//   When the user types freely without picking a suggestion the last confirmed
//   coords are preserved (cleared only when the field is emptied). This means:
//     - Editing the label text → coords remain from the last selection.
//     - Clearing the field entirely → [onSelected] is called with null,
//       signalling the caller to discard any stored coords.
//   Rationale: preserving coords is the least surprising for minor typo fixes,
//   while a full clear obviously signals "no location chosen".
// ---------------------------------------------------------------------------

class LocationAutocompleteField extends StatefulWidget {
  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.onSelected,
    this.hint = 'Search location',
    this.label,
    this.inputDecoration,
  });

  /// Pre-populated text controller. The caller owns it (create, dispose).
  final TextEditingController controller;

  /// Fired when the user picks a suggestion (non-null) or clears the field (null).
  final void Function(PlaceSuggestion? suggestion) onSelected;

  /// Hint text inside the field.
  final String hint;

  /// Optional label rendered above the field (for inline label use-cases).
  final String? label;

  /// Override the default InputDecoration (e.g. to match a sheet's style).
  final InputDecoration? inputDecoration;

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState
    extends State<LocationAutocompleteField> {
  final _geocoding = GeocodingService();
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  OverlayEntry? _overlay;
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  // ---- Search lifecycle --------------------------------------------------

  void _onChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      // Field cleared — signal caller to discard coords.
      _removeOverlay();
      setState(() => _suggestions = []);
      widget.onSelected(null);
      return;
    }

    if (value.trim().length < 3) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(value.trim());
    });
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await _geocoding.search(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _loading = false;
    });
    if (results.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _selectSuggestion(PlaceSuggestion suggestion) {
    widget.controller.text = suggestion.shortLabel;
    widget.onSelected(suggestion);
    _removeOverlay();
    setState(() => _suggestions = []);
  }

  // ---- Overlay management ------------------------------------------------

  void _showOverlay() {
    _removeOverlay();
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fieldWidth = renderBox.size.width;
    final fieldHeight = renderBox.size.height;

    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        width: fieldWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, fieldHeight + 2),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: AppColors.white,
            child: ListView.builder(
              shrinkWrap: true,
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              itemCount: _suggestions.length,
              itemBuilder: (ctx, i) {
                final suggestion = _suggestions[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => _selectSuggestion(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            suggestion.shortLabel,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  // ---- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final decoration = widget.inputDecoration ??
        InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : null,
        );

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        key: _fieldKey,
        controller: widget.controller,
        style: AppTextStyles.bodyMedium,
        onChanged: _onChanged,
        decoration: decoration,
      ),
    );
  }
}
