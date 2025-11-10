// lib/ui/settings/language_picker.dart
import 'package:flutter/material.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.current,
  });

  final String current; // 'en' | 'th'

  static Future<String?> show(BuildContext context, {required String current}) {
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.98),
      builder: (_) => LanguagePicker(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    String selected = current;
    return StatefulBuilder(
      builder: (context, setSt) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose language', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: 'en',
                groupValue: selected,
                onChanged: (v) => setSt(() => selected = v ?? 'en'),
                title: const Text('English (EN)'),
              ),
              RadioListTile<String>(
                value: 'th',
                groupValue: selected,
                onChanged: (v) => setSt(() => selected = v ?? 'th'),
                title: const Text('ไทย (TH)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, selected),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
