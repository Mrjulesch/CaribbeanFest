import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/cloudinary_service.dart';
import '../../core/repositories.dart';
import '../../widgets/app_scaffold.dart';

/// Gestión de la galería: el admin sube fotos (a Cloudinary) y las elimina.
class AdminGalleryScreen extends ConsumerWidget {
  const AdminGalleryScreen({super.key});

  void _snack(BuildContext c, String m) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);
    final api = ref.read(apiClientProvider);

    Future<void> addPhoto() async {
      if (!CloudinaryService.ready) {
        _snack(context, 'Cloudinary no está configurado.');
        return;
      }
      final picked = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (picked == null || picked.files.isEmpty || picked.files.first.bytes == null) return;
      final f = picked.files.first;
      if (context.mounted) _snack(context, 'Subiendo foto…');
      try {
        final url = await CloudinaryService.upload(f.bytes!, f.name);
        if (!context.mounted) return;
        final meta = await showDialog<Map<String, String>>(
          context: context,
          builder: (_) => const _PhotoMetaDialog(),
        );
        if (meta == null) return;
        await api.post('/gallery', data: {
          'imageUrl': url,
          'section': meta['section'],
          if ((meta['caption'] ?? '').isNotEmpty) 'caption': meta['caption'],
        });
        ref.invalidate(galleryProvider);
        if (context.mounted) _snack(context, 'Foto añadida a la galería');
      } catch (e) {
        if (context.mounted) _snack(context, 'Error al subir: $e');
      }
    }

    Future<void> deletePhoto(String id) async {
      try {
        await api.raw.delete('/gallery/$id');
        ref.invalidate(galleryProvider);
        if (context.mounted) _snack(context, 'Foto eliminada');
      } catch (e) {
        if (context.mounted) _snack(context, 'Error: $e');
      }
    }

    return AppScaffold(
      title: 'Galería (admin)',
      showBack: true,
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Foto'),
        onPressed: addPhoto,
      ),
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Sin fotos. Usa "Foto" para subir la primera.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: items
                .map((g) => Card(
                      child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: Image.network(g.imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                        ),
                        title: Text(g.caption?.isNotEmpty == true ? g.caption! : '(sin título)'),
                        subtitle: Text(g.section == 'FUTURE' ? 'Proyecto a futuro' : 'Lo que ha sucedido'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deletePhoto(g.id),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

/// Diálogo para elegir sección + título de la foto recién subida.
class _PhotoMetaDialog extends StatefulWidget {
  const _PhotoMetaDialog();
  @override
  State<_PhotoMetaDialog> createState() => _PhotoMetaDialogState();
}

class _PhotoMetaDialogState extends State<_PhotoMetaDialog> {
  String _section = 'PAST';
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Datos de la foto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _section,
            decoration: const InputDecoration(labelText: 'Sección', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'PAST', child: Text('Lo que ha sucedido')),
              DropdownMenuItem(value: 'FUTURE', child: Text('Proyectos a futuro')),
            ],
            onChanged: (v) => setState(() => _section = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _caption,
            decoration: const InputDecoration(labelText: 'Título / descripción (opcional)', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {'section': _section, 'caption': _caption.text.trim()}),
          child: const Text('Publicar'),
        ),
      ],
    );
  }
}
