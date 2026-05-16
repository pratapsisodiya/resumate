import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:resumate/services/ota_update_service.dart';
import 'package:resumate/shared/theme/app_theme.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.system_update_rounded,
                  color: Colors.white, size: 40),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 1200.ms,
                    curve: Curves.easeInOut),
            const SizedBox(height: 20),

            // Title
            Text(
              updateInfo.mandatory ? 'Update Required' : 'Update Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),

            // Version badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v${updateInfo.currentVersion} → v${updateInfo.latestVersion}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Changelog
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.new_releases_rounded,
                          size: 16, color: AppTheme.accent),
                      SizedBox(width: 6),
                      Text("What's New",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    updateInfo.changelog,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                if (!updateInfo.mandatory) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: updateInfo.mandatory ? 1 : 2,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Update Now'),
                    onPressed: () async {
                      await OTAUpdateService.downloadUpdate(
                          updateInfo.downloadUrl);
                      if (!updateInfo.mandatory && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, UpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.mandatory,
      builder: (_) => UpdateDialog(updateInfo: updateInfo),
    );
  }
}
