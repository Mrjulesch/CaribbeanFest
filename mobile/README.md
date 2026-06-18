# Caribbean Fest — App Flutter

App multiplataforma (Web · Android · iOS) para los 3 perfiles: público, árbitro y administrador.

## Requisitos
- Flutter SDK ≥ 3.3
- El backend corriendo (ver `../backend`)

## Correr
```bash
cd mobile
flutter pub get

# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Android (emulador): el host se ve como 10.0.2.2
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# iOS (simulador)
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Estructura
```
lib/
├── main.dart                 # entrypoint + tema + locale
├── core/
│   ├── config.dart           # URL base (--dart-define)
│   ├── api_client.dart       # Dio + JWT + refresh automático
│   ├── auth_controller.dart  # estado de sesión (Riverpod)
│   ├── token_storage.dart    # tokens en almacenamiento seguro
│   ├── live_match_service.dart # Socket.IO (scoring en vivo)
│   └── repositories.dart     # providers que consumen la API
├── models/models.dart        # Tournament, Category, Match, Standing...
├── routing/app_router.dart   # go_router + RoleGuard
└── features/
    ├── public/   # torneos, categoría (calendario+tabla), partido en vivo
    ├── auth/     # login
    ├── referee/  # partidos asignados + scoring en tiempo real
    └── admin/    # dashboard
```

## Flujos implementados
- **Público** (sin login): torneos → categorías → calendario/resultados, tabla de
  posiciones en vivo, partido en vivo (se actualiza por WebSocket).
- **Árbitro**: login → mis partidos → pantalla de scoring (+/- por set, cerrar set,
  finalizar partido) emitiendo por WebSocket.
- **Admin**: dashboard con torneos (formularios CRUD: próximo incremento de UI).

> Nota: este código fue escrito sin SDK de Flutter en la máquina de desarrollo, por lo
> que **no se compiló localmente**. Corre `flutter analyze` tras `flutter pub get` para
> el primer chequeo estático.
