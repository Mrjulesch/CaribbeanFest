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
          seedColor: const Color(0xFF0066CC),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // AppBar azul oscuro con texto/iconos blancos → contraste garantizado
        // para títulos y pestañas en toda la app (sobre el fondo degradado).
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF06203A),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      routerConfig: router,
    );
  }
}
