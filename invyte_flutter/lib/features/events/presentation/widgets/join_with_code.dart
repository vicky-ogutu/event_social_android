import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';

/// Asks for a private event's access code, joins it and opens the event.
Future<void> joinEventWithCode(BuildContext context, WidgetRef ref) async {
  final event = await showDialog<Event>(context: context, builder: (_) => const _JoinWithCodeDialog());
  if (event == null || !context.mounted) return;
  invalidateEvents(ref, eventId: event.id);
  context.push(Routes.event(event.id));
}

class _JoinWithCodeDialog extends ConsumerStatefulWidget {
  const _JoinWithCodeDialog();

  @override
  ConsumerState<_JoinWithCodeDialog> createState() => _JoinWithCodeDialogState();
}

class _JoinWithCodeDialogState extends ConsumerState<_JoinWithCodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final event = await ref.read(eventRepositoryProvider).joinByCode(_code.text);
      if (mounted) Navigator.pop(context, event);
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join with code'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the access code from your invitation.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              autofocus: true,
              enabled: !_joining,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.go,
              onFieldSubmitted: (_) => _join(),
              validator: (v) => Validators.required(v, 'Access code'),
              decoration: InputDecoration(
                hintText: 'Access code',
                prefixIcon: const Icon(Icons.key_rounded),
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _joining ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _joining ? null : _join,
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          child: Text(_joining ? 'Joining…' : 'Join'),
        ),
      ],
    );
  }
}
