import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final storage = await StorageService.create();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
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
    return MaterialApp.router(
      title: 'Pixel Cross',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
