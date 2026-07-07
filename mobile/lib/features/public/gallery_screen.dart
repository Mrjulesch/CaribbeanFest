import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

/// Galería pública: fotos del torneo ("Lo que ha sucedido") y "Proyectos a futuro".
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);

    return AppScaffold(
      title: 'Galería',
      showBack: true,
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => const Center(
            child: Text('No se pudo cargar la galería', style: TextStyle(color: Colors.white))),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Aún no hay fotos publicadas.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }
          final past = items.where((g) => g.section == 'PAST').toList();
          final future = items.where((g) => g.section == 'FUTURE').toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(galleryProvider),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (past.isNotEmpty) ...[
                  _header('📸 Lo que ha sucedido'),
                  _grid(context, past),
                ],
                if (future.isNotEmpty) ...[
                  _header('🚀 Proyectos a futuro'),
                  _grid(context, future),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _grid(BuildContext context, List<GalleryItem> items) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 1100 ? 4 : (w >= 700 ? 3 : 2);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (_, i) => _PhotoCard(item: items[i]),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.item});
  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (c, w, p) =>
                  p == null ? w : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorBuilder: (c, e, s) => const ColoredBox(
                color: Color(0xFFE0E0E0),
                child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ),
          if (item.caption != null && item.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(item.caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
