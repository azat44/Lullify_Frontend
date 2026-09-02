import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lullify_mobile/core/app.dart';
import 'package:lullify_mobile/core/network/dio_client.dart';
import 'package:lullify_mobile/presentation/providers/auth_provider.dart';
import 'package:lullify_mobile/services/audio_handler.dart';

late LullifyAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise audio_service
  audioHandler = await AudioService.init(
    builder: () => LullifyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.lullify.audio',
      androidNotificationChannelName: 'Lullify Radio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

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