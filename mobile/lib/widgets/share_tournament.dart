import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Construye el enlace público a la vista del torneo (consulta sin login).
/// La app web usa estrategia de hash, por eso el "/#/".
String tournamentPublicUrl(String tournamentId) {
  final origin = Uri.base.origin; // ej. http://localhost:8080
  return '$origin/#/tournament/$tournamentId';
}

/// Diálogo para compartir un torneo: muestra el enlace, un QR, y permite
/// copiarlo o compartirlo (WhatsApp, redes, etc. vía el menú del sistema).
Future<void> showShareTournamentDialog(
  BuildContext context, {
  required String tournamentId,
  String? tournamentName,
  bool isPublished = true,
}) {
  final url = tournamentPublicUrl(tournamentId);
  final shareText = tournamentName != null
      ? '🏐 Sigue "$tournamentName" en vivo: resultados, posiciones y canchas\n$url'
      : '🏐 Sigue el torneo en vivo: resultados, posiciones y canchas\n$url';

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Compartir torneo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPublished)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 6),
                  Expanded(child: Text('Está en borrador. Publícalo para que el público lo vea.', style: TextStyle(fontSize: 12))),
                ]),
              ),
            const Text('Cualquiera con este enlace verá calendario, resultados, posiciones y canchas:',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: QrImageView(data: url, size: 180),
            ),
            const SizedBox(height: 12),
            SelectableText(url, style: const TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
            }
          },
        ),
        FilledButton.icon(
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Compartir'),
          onPressed: () => Share.share(shareText),
        ),
      ],
    ),
  );
}
