import 'package:flutter/material.dart';

class TabButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool selected;

  /// Shows the button faded. It stays tappable, e.g. to explain why the
  /// feature is unavailable.
  final bool disabled;

  const TabButton({
    super.key,
    this.icon,
    this.onTap,
    this.tooltip = '',
    this.selected = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          selected: selected,
          enabled: !disabled,
          child: Container(
            height: 40.0,
            width: 40.0,
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.secondary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: const BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                onTap: onTap,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Opacity(
                      opacity: disabled ? 0.38 : 1.0,
                      child: Icon(
                        icon,
                        color: selected
                            ? theme.colorScheme.secondary
                            : theme.iconTheme.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
