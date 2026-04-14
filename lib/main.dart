import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
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

  // Seed pre-configured accounts
  try {
    await AuthService.seedAccounts();
  } catch (_) {
    // Seeding may fail if already done or no permissions yet
  }

  // Initialize EmailJS
  EmailService.init();

  runApp(const CrisisSyncApp());
}

class CrisisSyncApp extends StatelessWidget {
  const CrisisSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final router = AppRouter.router(authProvider);

          return MaterialApp.router(
            title: 'CrisisSync — Crisis Response Platform',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
