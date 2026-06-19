import 'package:flutter/material.dart';

/// Diálogos de formulario reutilizables para el panel de administración.

class FieldSpec {
  FieldSpec(this.key, this.label, {this.initial, this.keyboard});
  final String key;
  final String label;
  final String? initial;
  final TextInputType? keyboard;
}

/// Diálogo genérico de campos de texto. Devuelve un mapa key→valor, o null si se cancela.
Future<Map<String, String>?> showFormDialog(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  String okLabel = 'Guardar',
}) {
  final controllers = {for (final f in fields) f.key: TextEditingController(text: f.initial ?? '')};
  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: fields
              .map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextField(
                      controller: controllers[f.key],
                      keyboardType: f.keyboard,
                      decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
                    ),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, {for (final f in fields) f.key: controllers[f.key]!.text.trim()}),
          child: Text(okLabel),
        ),
      ],
    ),
  );
}

/// Diálogo de creación de torneo: nombre + fechas de inicio/fin.
Future<Map<String, dynamic>?> showCreateTournamentDialog(BuildContext context) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => const _TournamentDialog(title: 'Nuevo torneo', okLabel: 'Crear'),
  );
}

/// Diálogo de edición de torneo (prerellena nombre y fechas).
Future<Map<String, dynamic>?> showEditTournamentDialog(
  BuildContext context, {
  required String name,
  DateTime? start,
  DateTime? end,
  String? paymentLink,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _TournamentDialog(
      title: 'Editar torneo',
      okLabel: 'Guardar',
      initialName: name,
      initialStart: start,
      initialEnd: end,
      initialPaymentLink: paymentLink,
    ),
  );
}

class _TournamentDialog extends StatefulWidget {
  const _TournamentDialog({
    required this.title,
    required this.okLabel,
    this.initialName,
    this.initialStart,
    this.initialEnd,
    this.initialPaymentLink,
  });
  final String title;
  final String okLabel;
  final String? initialName;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final String? initialPaymentLink;

  @override
  State<_TournamentDialog> createState() => _TournamentDialogState();
}

class _TournamentDialogState extends State<_TournamentDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName ?? '');
  late final TextEditingController _paymentLink =
      TextEditingController(text: widget.initialPaymentLink ?? '');
  late DateTime? _start = widget.initialStart;
  late DateTime? _end = widget.initialEnd;

  Future<void> _pick(bool start) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: start ? now : (_start ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d != null) setState(() => start ? _start = d : _end = d);
  }

  String _fmt(DateTime? d) => d == null ? 'Elegir' : '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre del torneo', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(true), icon: const Icon(Icons.event), label: Text('Inicio: ${_fmt(_start)}'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(false), icon: const Icon(Icons.event), label: Text('Fin: ${_fmt(_end)}'))),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _paymentLink,
            decoration: const InputDecoration(
              labelText: 'Link de pago Wompi (opcional)',
              hintText: 'https://checkout.wompi.co/l/...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().length < 3 || _start == null || _end == null) return;
            Navigator.pop(context, {
              'name': _name.text.trim(),
              'startDate': _start!.toIso8601String(),
              'endDate': _end!.toIso8601String(),
              'paymentLink': _paymentLink.text.trim(),
            });
          },
          child: Text(widget.okLabel),
        ),
      ],
    );
  }
}

/// Diálogo de creación de categoría: nombre + rama + formato.
Future<Map<String, String>?> showCreateCategoryDialog(BuildContext context) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => const _CategoryDialog(),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog();
  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _name = TextEditingController();
  String _gender = 'MALE';
  String _format = 'ROUND_ROBIN';
  int _bestOf = 5;

  static const _formats = {
    'ROUND_ROBIN': 'Todos contra todos',
    'GROUPS_PLAYOFF': 'Grupos + eliminación',
    'SINGLE_ELIM': 'Eliminación simple',
    'QUADRANGULAR': 'Cuadrangular',
    'HEXAGONAL': 'Hexagonal',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva categoría'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre (ej. Sub 18, Libre)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(labelText: 'Rama', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Masculina')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Femenina')),
            ],
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _format,
            decoration: const InputDecoration(labelText: 'Sistema de competencia', border: OutlineInputBorder()),
            items: _formats.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _format = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _bestOf,
            decoration: const InputDecoration(labelText: 'Formato de sets', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 3, child: Text('Mejor de 3 (2 sets de 3)')),
              DropdownMenuItem(value: 5, child: Text('Mejor de 5 (3 sets de 5)')),
            ],
            onChanged: (v) => setState(() => _bestOf = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'name': _name.text.trim(),
              'gender': _gender,
              'format': _format,
              'bestOf': '$_bestOf',
            });
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

/// Diálogo para editar el marcador de un partido (best-of-3 o best-of-5).
/// `initial` mapea setNumber → (home, away). Devuelve la lista de sets con datos.
Future<List<Map<String, int>>?> showEditScoreDialog(
  BuildContext context, {
  required int maxSets,
  required Map<int, List<int>> initial,
}) {
  return showDialog<List<Map<String, int>>>(
    context: context,
    builder: (ctx) => _EditScoreDialog(maxSets: maxSets, initial: initial),
  );
}

class _EditScoreDialog extends StatefulWidget {
  const _EditScoreDialog({required this.maxSets, required this.initial});
  final int maxSets;
  final Map<int, List<int>> initial;
  @override
  State<_EditScoreDialog> createState() => _EditScoreDialogState();
}

class _EditScoreDialogState extends State<_EditScoreDialog> {
  late final List<List<TextEditingController>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = List.generate(widget.maxSets, (i) {
      final n = i + 1;
      final v = widget.initial[n];
      return [
        TextEditingController(text: v != null ? '${v[0]}' : ''),
        TextEditingController(text: v != null ? '${v[1]}' : ''),
      ];
    });
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r[0].dispose();
      r[1].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar marcador'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Deja vacíos los sets no jugados.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            ...List.generate(widget.maxSets, (i) {
              final isDecider = (i + 1) == widget.maxSets;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SizedBox(width: 64, child: Text('Set ${i + 1}${isDecider ? " (15)" : " (25)"}')),
                  Expanded(child: _num(_rows[i][0], 'Local')),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-')),
                  Expanded(child: _num(_rows[i][1], 'Visit.')),
                ]),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final sets = <Map<String, int>>[];
            for (var i = 0; i < _rows.length; i++) {
              final h = int.tryParse(_rows[i][0].text);
              final a = int.tryParse(_rows[i][1].text);
              if (h != null && a != null) {
                sets.add({'setNumber': i + 1, 'homePoints': h, 'awayPoints': a});
              }
            }
            Navigator.pop(context, sets);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _num(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(hintText: label, isDense: true, border: const OutlineInputBorder()),
      );
}

/// Selector de fecha simple (para generar fixture). Devuelve ISO o null.
Future<String?> pickDateIso(BuildContext context) async {
  final now = DateTime.now();
  final d = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 3),
  );
  return d?.toIso8601String();
}
