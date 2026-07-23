import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lullify_mobile/core/app.dart';
import 'package:lullify_mobile/core/network/dio_client.dart';
import 'package:lullify_mobile/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GoogleFonts.pendingFonts([
    GoogleFonts.vt323(),
    GoogleFonts.quicksand(),
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        onSessionExpiredProvider.overrideWith((ref) {
          return () => ref.read(authProvider.notifier).sessionExpired();
        }),
      ],
      child: const LullifyApp(),
    ),
  );
}