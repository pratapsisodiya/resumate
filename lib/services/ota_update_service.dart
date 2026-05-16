import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class OTAUpdateService {
  static const String updateCheckUrl =
      'https://raw.githubusercontent.com/pratapsisodiya/resumate/main/version.json';

  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http
          .get(Uri.parse(updateCheckUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final latestVersion = data['version'] as String;
        final downloadUrl = data['downloadUrl'] as String;
        final changelog = data['changelog'] as String?;
        final mandatory = data['mandatory'] as bool? ?? false;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            downloadUrl: downloadUrl,
            changelog: changelog ?? 'Bug fixes and improvements',
            mandatory: mandatory,
          );
        }
      }
    } catch (e) {
      debugPrint('OTA update check failed: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.tryParse).toList();
    final latestParts = latest.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final c = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
      final l = i < latestParts.length ? (latestParts[i] ?? 0) : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static Future<void> downloadUpdate(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String changelog;
  final bool mandatory;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.changelog,
    required this.mandatory,
  });
}
