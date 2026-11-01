import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'app_image.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.mine,
    this.time,
    this.authorName,
    this.authorAvatar,
    this.showAuthor = false,
  });

  final String text;
  final bool mine;
  final DateTime? time;
  final String? authorName;
  final String? authorAvatar;

  /// Group chats show the sender's avatar and name on incoming messages.
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        gradient: mine ? AppColors.brandGradient : null,
        color: mine ? null : theme.colorScheme.surface,
        border: mine ? null : Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(mine ? 20 : 6),
          bottomRight: Radius.circular(mine ? 6 : 20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAuthor && !mine && authorName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(authorName!,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppColors.accentFor(authorName!), fontWeight: FontWeight.w800)),
            ),
          Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: mine ? Colors.white : null)),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.bottomRight,
            widthFactor: 1,
            child: Text(
              Fmt.clock(time),
              style: theme.textTheme.labelSmall?.copyWith(
                color: mine ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAuthor && !mine) ...[
            UserAvatar(name: authorName ?? '', url: authorAvatar, size: 28),
            const SizedBox(width: 8),
          ],
          bubble,
        ],
      ),
    );
  }
}

class ChatInput extends StatefulWidget {
  const ChatInput({super.key, required this.onSend, this.hint = 'Message…'});

  final Future<void> Function(String text) onSend;
  final String hint;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      _controller.clear();
    } catch (_) {
      // The caller reports the error; keep the text so the user can retry.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSend = _controller.text.trim().isNotEmpty && !_sending;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedScale(
                scale: canSend ? 1 : 0.85,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: canSend ? AppColors.brandGradient : null,
                    color: canSend ? null : theme.colorScheme.surfaceContainerHigh,
                  ),
                  child: IconButton(
                    onPressed: canSend ? _send : null,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.send_rounded, color: canSend ? Colors.white : theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Today" / "Yesterday" / date separators for chat lists.
class DayDivider extends StatelessWidget {
  const DayDivider({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays;
    final label = days == 0 ? 'Today' : (days == 1 ? 'Yesterday' : Fmt.date(date));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
  }
}

bool isSameDay(DateTime? a, DateTime? b) =>
    a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;
