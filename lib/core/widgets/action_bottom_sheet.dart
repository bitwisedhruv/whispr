import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:whispr/core/theme.dart';

class ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  ActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });
}

class ActionBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ActionItem> actions;

  const ActionBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: const BoxDecoration(
        color: WhisprTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          ...actions.map((action) => _buildActionTile(context, action)),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, ActionItem action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          action.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GlassContainer.frostedGlass(
              height: 70,
              width: constraints.maxWidth,
              borderRadius: BorderRadius.circular(20),
              borderWidth: 1,
              borderColor: Colors.white.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (action.color ?? Colors.white).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action.icon,
                        size: 20,
                        color: action.color ?? Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      action.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: action.color ?? Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: (action.color ?? Colors.white).withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
