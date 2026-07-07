import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los símbolos de fecha en español (DateFormat(..., 'es')).
  await initializeDateFormatting('es', null);
  runApp(const ProviderScope(child: CaribbeanFestApp()));
}

class CaribbeanFestApp extends ConsumerWidget {
  const CaribbeanFestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Caribbean Fest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A4FA0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // AppBar oscuro con texto/iconos blancos; el degradado se pinta en AppScaffold.
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF06203A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        // Tarjetas más redondeadas y con relieve → look moderno.
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
