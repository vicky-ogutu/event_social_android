import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_picking.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/social_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.eventId});

  /// Pre-selects the event when opened from an event page.
  final int? eventId;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  static const _maxPhotos = 4;

  final _content = TextEditingController();
  late int? _eventId = widget.eventId;
  final _photos = <String>[];
  bool _posting = false;
  String? _progress;

  @override
  void initState() {
    super.initState();
    _content.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    final paths = await pickImagePaths(limit: remaining);
    if (paths.isNotEmpty) setState(() => _photos.addAll(paths.take(remaining)));
  }

  Future<void> _post() async {
    final eventId = _eventId;
    if (eventId == null) {
      showSnack(context, 'Choose which event this moment is from.', error: true);
      return;
    }
    setState(() => _posting = true);
    try {
      final repository = ref.read(socialRepositoryProvider);
      final urls = <String>[];
      for (final (i, path) in _photos.indexed) {
        setState(() => _progress = 'Uploading photo ${i + 1} of ${_photos.length}…');
        urls.add(await repository.uploadMedia(path));
      }
      setState(() => _progress = 'Posting…');
      await ref
          .read(feedProvider(null).notifier)
          .publish(eventId: eventId, content: _content.text.trim(), mediaUrls: urls);
      ref.invalidate(feedProvider(eventId));
      if (!mounted) return;
      showSnack(context, 'Moment shared');
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final mine = ref.watch(myEventsProvider).value ?? const <Event>[];
    final public = ref.watch(discoverEventsProvider(const EventQuery())).value ?? const <Event>[];
    final events = {for (final e in [...mine, ...public]) e.id: e}.values.toList();
    final canPost = _content.text.trim().isNotEmpty && !_posting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New moment'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: canPost ? _post : null,
              style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
              child: _posting
                  ? const SizedBox.square(
                      dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              UserAvatar(name: user?.fullName ?? '', url: user?.profilePicture),
              const SizedBox(width: 12),
              Text(user?.fullName ?? '', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _content,
            autofocus: true,
            minLines: 4,
            maxLines: 12,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: "What's happening at your event?",
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
          _PhotoStrip(
            photos: _photos,
            max: _maxPhotos,
            enabled: !_posting,
            onAdd: _addPhotos,
            onRemove: (i) => setState(() => _photos.removeAt(i)),
          ),
          if (_progress != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text(_progress!, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text('Event', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: events.any((e) => e.id == _eventId) ? _eventId : null,
            isExpanded: true,
            decoration: const InputDecoration(hintText: 'Choose an event', prefixIcon: Icon(Icons.celebration_rounded)),
            items: [
              for (final e in events) DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: _posting ? null : (v) => setState(() => _eventId = v),
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.photos,
    required this.max,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final int max;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (i, path) in photos.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(path), width: 96, height: 96, fit: BoxFit.cover),
                  ),
                  if (enabled)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(i),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (photos.length < max)
            InkWell(
              onTap: enabled ? onAdd : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outline, width: 1.4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary),
                    const SizedBox(height: 4),
                    Text('${photos.length}/$max', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
