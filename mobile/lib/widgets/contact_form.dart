import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

/// Diálogo del formulario "Contáctanos". Envía el mensaje a la API (público).
Future<void> showContactDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ContactDialog(ref: ref),
  );
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({required this.ref});
  final WidgetRef ref;
  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_name.text.trim().length < 2 || !_email.text.contains('@') || _message.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa nombre, correo y un mensaje.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.ref.read(apiClientProvider).post('/contact', data: {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'message': _message.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Mensaje enviado! Te responderemos pronto.')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contáctanos'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Dudas o quieres organizar tu torneo? Escríbenos.',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _message,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Mensaje', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _sending ? null : _send,
          icon: const Icon(Icons.send, size: 18),
          label: Text(_sending ? 'Enviando…' : 'Enviar'),
        ),
      ],
    );
  }
}
