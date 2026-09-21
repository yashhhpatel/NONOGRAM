import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final storage = await StorageService.create();
  final notifications = NotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const NonogramApp(),
    ),
  );
}

class NonogramApp extends ConsumerWidget {
  const NonogramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instantiate billing early so it can connect and deliver owned purchases.
    ref.watch(billingServiceProvider);
    final router = ref.watch(routerProvider);

    final modeIndex =
        ref.watch(profileControllerProvider.select((p) => p.themeModeIndex));
    final themeMode = switch (modeIndex) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    // Resolve the effective brightness so AppTheme's neutral getters match the
    // theme MaterialApp actually renders.
    final platform = MediaQuery.platformBrightnessOf(context);
    AppTheme.brightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };

    return MaterialApp.router(
      title: 'Pixel Cross',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
