import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A generic two-or-more-option segmented control with a sliding
/// highlight (200ms, easeInOutCubic). Used for both Stats' 7/30-day
/// toggle and Today's List/Timeline toggle — extracted here rather than
/// duplicated a second time.
class SegmentedToggle<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selectedIndex = options.indexOf(value);
    final count = options.length;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: palette.surfaceRaised, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            alignment: Alignment(-1 + (2 * selectedIndex / (count - 1)), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              child: Container(
                height: 32,
                decoration: BoxDecoration(color: palette.purpleTint, borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ),
          Row(
            children: options.map((option) {
              final selected = option == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Text(
                      labelBuilder(option),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                        color: selected ? palette.textPrimary : palette.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
