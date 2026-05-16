import 'package:flutter/material.dart';
import 'package:resumate/app.dart';
import 'package:resumate/data/local_storage.dart';
import 'package:resumate/services/ota_update_service.dart';
import 'package:resumate/shared/widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();

  final storage = LocalStorage();
  final onboarded = await storage.getSetting<bool>('onboarded') ?? false;

  runApp(ResumateApp(showOnboarding: !onboarded));

  // Check for OTA updates after app starts
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final updateInfo = await OTAUpdateService.checkForUpdates();
      if (updateInfo != null && context.mounted) {
        UpdateDialog.show(context, updateInfo);
      }
    }
  });
}
