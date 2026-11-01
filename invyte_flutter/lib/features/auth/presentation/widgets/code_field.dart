import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Six-box one-time-code input backed by a single text field, so paste and
/// SMS/email autofill work naturally.
class CodeField extends StatefulWidget {
  const CodeField({super.key, required this.controller, this.onCompleted, this.enabled = true});

  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final bool enabled;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    final text = widget.controller.text;
    if (text.length == 6) widget.onCompleted?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = widget.controller.text;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          // The real input: invisible but focusable, so the keyboard and
          // autofill target it.
          Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              showCursor: false,
              enableInteractiveSelection: false,
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) SizedBox(width: i == 3 ? 16 : 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: i == text.length && _focus.hasFocus ? AppColors.primary : theme.colorScheme.outline,
                        width: i == text.length && _focus.hasFocus ? 2 : 1.2,
                      ),
                    ),
                    child: Text(
                      i < text.length ? text[i] : '',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// "Resend code" link with a cooldown so codes can't be spammed.
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({super.key, required this.onResend, this.cooldown = const Duration(seconds: 45)});

  final Future<void> Function() onResend;
  final Duration cooldown;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  late int _remaining = widget.cooldown.inSeconds;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _remaining = widget.cooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await widget.onResend();
      _startCooldown();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _remaining > 0;
    return TextButton(
      onPressed: waiting || _sending ? null : _resend,
      child: Text(waiting ? 'Resend code in ${_remaining}s' : (_sending ? 'Sending…' : 'Resend code')),
    );
  }
}
