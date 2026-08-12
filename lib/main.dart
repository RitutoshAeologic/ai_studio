import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'app/app.dart';
import 'core/utils/logger.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock device orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize GetStorage for fast local persistence
  await GetStorage.init();
  
  // Initialize Firebase App with options from google-services.json
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.i('Firebase initialized successfully');
  } catch (e, stackTrace) {
    Logger.e('Failed to initialize Firebase', e, stackTrace);
  }

  runApp(const AiStudioApp());
}
