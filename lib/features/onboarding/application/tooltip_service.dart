import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:devnotes/core/l10n/l10n.dart';

class TooltipService {
  static Future<bool> shouldShow(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('tooltip_$key') ?? false);
  }

  static Future<void> markShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tooltip_$key', true);
  }

  static void showTooltips({
    required BuildContext context,
    required String tooltipKey,
    required List<TargetFocus> targets,
  }) async {
    if (!await shouldShow(tooltipKey)) return;
    if (!context.mounted) return;

    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      textSkip: context.l10n.commonSkip.toUpperCase(),
      onFinish: () => markShown(tooltipKey),
      onSkip: () {
        markShown(tooltipKey);
        return true;
      },
    );

    tutorial.show(context: context);
  }

  static TargetFocus createTarget({
    required GlobalKey key,
    required String title,
    required String description,
    ContentAlign align = ContentAlign.bottom,
  }) {
    return TargetFocus(
      keyTarget: key,
      alignSkip: Alignment.topRight,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(description,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            );
          },
        ),
      ],
    );
  }
}
