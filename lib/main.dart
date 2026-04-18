import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:crisissync/config/firebase_config.dart';
import 'package:crisissync/config/router.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'package:crisissync/providers/incident_provider.dart';
import 'package:crisissync/providers/staff_provider.dart';
import 'package:crisissync/services/auth_service.dart';
import 'package:crisissync/services/email_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseConfig.webOptions,
  );

  // Enable Firestore persistence for offline support on web
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Seed pre-configured accounts (non-blocking)
  try {
    await AuthService.seedAccounts().timeout(const Duration(seconds: 5));
  } catch (e) {
    // Seeding may fail if already done, no permissions, or offline — non-critical
    debugPrint('Seed accounts: $e');
  }

  // Initialize EmailJS
  EmailService.init();

  runApp(const CrisisSyncApp());
}

class CrisisSyncApp extends StatefulWidget {
  const CrisisSyncApp({super.key});

  @override
  State<CrisisSyncApp> createState() => _CrisisSyncAppState();
}

class _CrisisSyncAppState extends State<CrisisSyncApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRouter.router(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
      ],
      child: MaterialApp.router(
        title: 'CrisisSync — Crisis Response Platform',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
