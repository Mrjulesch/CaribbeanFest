import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/cloudinary_service.dart';
import '../../core/repositories.dart';
import '../../widgets/app_scaffold.dart';

/// Formulario público de inscripción de un equipo. La organización lo valida.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _PlayerCtrls {
  final fullName = TextEditingController();
  final document = TextEditingController();
  final age = TextEditingController();
  final eps = TextEditingController();
  final jersey = TextEditingController();
  void dispose() {
    fullName.dispose();
    document.dispose();
    age.dispose();
    eps.dispose();
    jersey.dispose();
  }
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  String? _tournamentId;
  String? _categoryId;
  final _teamName = TextEditingController();
  final _clubName = TextEditingController();
  final _city = TextEditingController();
  final _contactName = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactPhone = TextEditingController();
  final List<_PlayerCtrls> _players = [_PlayerCtrls()];
  bool _submitting = false;
  String? _consentUrl; // PDF subido a Cloudinary
  String? _consentName;
  bool _uploadingConsent = false;

  Future<void> _pickConsent() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final f = picked.files.first;
    if (f.bytes == null) return;
    setState(() => _uploadingConsent = true);
    try {
      final url = await CloudinaryService.uploadPdf(f.bytes!, f.name);
      setState(() {
        _consentUrl = url;
        _consentName = f.name;
      });
    } catch (e) {
      if (mounted) _snack('No se pudo subir el PDF: $e');
    } finally {
      if (mounted) setState(() => _uploadingConsent = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_teamName, _clubName, _city, _contactName, _contactEmail, _contactPhone]) {
      c.dispose();
    }
    for (final p in _players) {
      p.dispose();
    }
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    if (_tournamentId == null || _categoryId == null) return _snack('Elige torneo y categoría.');
    if (_teamName.text.trim().length < 2) return _snack('Escribe el nombre del equipo.');
    if (!_contactEmail.text.contains('@') || _contactName.text.trim().isEmpty || _contactPhone.text.trim().isEmpty) {
      return _snack('Completa los datos de contacto.');
    }
    final players = _players
        .where((p) => p.fullName.text.trim().isNotEmpty)
        .map((p) => {
              'fullName': p.fullName.text.trim(),
              if (p.document.text.trim().isNotEmpty) 'document': p.document.text.trim(),
              if (int.tryParse(p.age.text) != null) 'age': int.parse(p.age.text),
              if (p.eps.text.trim().isNotEmpty) 'eps': p.eps.text.trim(),
              if (int.tryParse(p.jersey.text) != null) 'jerseyNumber': int.parse(p.jersey.text),
            })
        .toList();
    if (players.isEmpty) return _snack('Añade al menos un jugador.');

    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/registrations', data: {
        'tournamentId': _tournamentId,
        'categoryId': _categoryId,
        'teamName': _teamName.text.trim(),
        if (_clubName.text.trim().isNotEmpty) 'clubName': _clubName.text.trim(),
        if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
        if (_consentUrl != null) 'consentUrl': _consentUrl,
        'contactName': _contactName.text.trim(),
        'contactEmail': _contactEmail.text.trim(),
        'contactPhone': _contactPhone.text.trim(),
        'players': players,
      });
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¡Inscripción enviada!'),
          content: const Text(
              'La organización de Caribbean Fest revisará tu solicitud y validará la inscripción. Gracias.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/');
              },
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _snack('Error al enviar: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(tournamentsProvider);

    return AppScaffold(
      title: 'Inscribir equipo',
      showBack: true,
      body: tournaments.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No hay torneos abiertos para inscripción por ahora.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            );
          }
          // Categorías del torneo elegido.
          final categories = _tournamentId == null
              ? <DropdownMenuItem<String>>[]
              : (list.firstWhere((t) => t.id == _tournamentId).categories)
                  .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} · ${c.genderLabel}')))
                  .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section('Torneo y categoría'),
              _card(Column(children: [
                DropdownButtonFormField<String>(
                  value: _tournamentId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Torneo', border: OutlineInputBorder()),
                  items: list.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (v) => setState(() {
                    _tournamentId = v;
                    _categoryId = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoría / rama', border: OutlineInputBorder()),
                  items: categories,
                  onChanged: categories.isEmpty ? null : (v) => setState(() => _categoryId = v),
                ),
              ])),
              _section('Datos del equipo'),
              _card(Column(children: [
                _tf(_teamName, 'Nombre del equipo'),
                _tf(_clubName, 'Club (opcional)'),
                _tf(_city, 'Ciudad (opcional)'),
              ])),
              if (CloudinaryService.ready) ...[
                _section('Consentimiento de uso de imagen (PDF)'),
                _card(Row(children: [
                  Expanded(
                    child: Text(
                      _consentName ?? 'Adjunta el consentimiento del club (solo PDF).',
                      style: TextStyle(color: _consentUrl != null ? Colors.green : Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_uploadingConsent)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    OutlinedButton.icon(
                      icon: Icon(_consentUrl != null ? Icons.check : Icons.upload_file),
                      label: Text(_consentUrl != null ? 'Cambiar' : 'Adjuntar PDF'),
                      onPressed: _pickConsent,
                    ),
                ])),
              ],
              _section('Contacto del delegado'),
              _card(Column(children: [
                _tf(_contactName, 'Nombre del delegado'),
                _tf(_contactEmail, 'Correo', keyboard: TextInputType.emailAddress),
                _tf(_contactPhone, 'Teléfono', keyboard: TextInputType.phone),
              ])),
              _section('Jugadores (máx. 14)'),
              ..._players.asMap().entries.map((e) => _playerCard(e.key, e.value)),
              const SizedBox(height: 8),
              if (_players.length < 14)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir jugador'),
                  onPressed: () => setState(() => _players.add(_PlayerCtrls())),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.send),
                label: Text(_submitting ? 'Enviando…' : 'Enviar inscripción'),
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _card(Widget child) => Card(child: Padding(padding: const EdgeInsets.all(12), child: child));

  Widget _tf(TextEditingController c, String label, {TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        ),
      );

  Widget _playerCard(int i, _PlayerCtrls p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Text('Jugador ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_players.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() {
                    _players.removeAt(i).dispose();
                  }),
                ),
            ]),
            _tf(p.fullName, 'Nombre completo'),
            _tf(p.document, 'N° de identidad', keyboard: TextInputType.number),
            Row(children: [
              Expanded(child: _tf(p.age, 'Edad', keyboard: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: _tf(p.jersey, 'N° camiseta', keyboard: TextInputType.number)),
            ]),
            _tf(p.eps, 'EPS (si aplica)'),
          ],
        ),
      ),
    );
  }
}
