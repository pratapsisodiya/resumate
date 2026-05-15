import 'package:flutter/material.dart';
import 'package:resumate/app.dart';
import 'package:resumate/data/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();

  final storage = LocalStorage();
  final onboarded = await storage.getSetting<bool>('onboarded') ?? false;

  runApp(ResumateApp(showOnboarding: !onboarded));
}
