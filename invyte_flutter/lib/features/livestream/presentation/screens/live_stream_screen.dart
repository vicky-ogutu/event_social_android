import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' show VideoTrack, VideoTrackRenderer, VideoViewFit;

import '../../../../core/di/core_providers.dart';
import '../../../../core/payments/payment_gateway.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../data/live/live_sessions.dart';
import '../../domain/entities/livestream.dart';
import '../providers/livestream_providers.dart';

/// Host studio and viewer experience for an event's live broadcast.
class LiveStreamScreen extends ConsumerWidget {
  const LiveStreamScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventDetailProvider(eventId));
    final stream = ref.watch(livestreamForEventProvider(eventId));
    Widget body;
    if (event.hasValue && stream.hasValue) {
      body = _LiveView(event: event.requireValue, initialStream: stream.value);
    } else if (event.hasError || stream.hasError) {
      body = Center(
        child: Text((event.error ?? stream.error).toString(), style: const TextStyle(color: Colors.white)),
      );
    } else {
      body = const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(backgroundColor: Colors.black, body: body),
    );
  }
}

class _LiveView extends ConsumerStatefulWidget {
  const _LiveView({required this.event, required this.initialStream});

  final Event event;
  final Livestream? initialStream;

  @override
  ConsumerState<_LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends ConsumerState<_LiveView> {
  late Livestream? _stream = widget.initialStream;
  LiveBroadcast? _broadcast;
  LiveViewer? _viewer;
  bool _broadcasting = false;
  bool _busy = false;
  bool _startingViewer = false;
  DateTime? _onAirSince;
  late final _passPrice = TextEditingController(
    text: (widget.initialStream?.price ?? 0) > 0 ? widget.initialStream!.price.toStringAsFixed(2) : '',
  );

  bool get _isHost => ref.read(currentUserProvider)?.id == widget.event.organizerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = _stream;
      if (!_isHost && s != null && s.isLive && s.hasAccess) _watch(s);
    });
  }

  @override
  void dispose() {
    _broadcast?.dispose();
    _viewer?.dispose();
    _passPrice.dispose();
    super.dispose();
  }

  // ---------------- Host ----------------

  Future<void> _goLive() async {
    setState(() => _busy = true);
    final repo = ref.read(livestreamRepositoryProvider);
    LiveBroadcast? broadcast;
    try {
      final price = double.tryParse(_passPrice.text.trim()) ?? 0;
      final stream = await repo.prepare(widget.event.id, price: price);
      broadcast = ref.read(liveSessionFactoryProvider).broadcast(stream.id, await repo.joinInfo(stream.id));
      await broadcast.openCamera();
      await repo.start(stream.id);
      await broadcast.goLive();
      _broadcast = broadcast;
      invalidateEvents(ref, eventId: widget.event.id);
      if (mounted) {
        setState(() {
          _stream = stream;
          _broadcasting = true;
          _onAirSince = DateTime.now();
        });
      }
    } catch (e) {
      await broadcast?.dispose();
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    final ok = await confirmAction(
      context,
      title: 'End broadcast?',
      message: 'Viewers will be disconnected.',
      confirmLabel: 'End stream',
      destructive: true,
    );
    final stream = _stream;
    if (!ok || stream == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(livestreamRepositoryProvider).end(stream.id);
      await _broadcast?.dispose();
      _broadcast = null;
      invalidateEvents(ref, eventId: widget.event.id);
      ref.invalidate(livestreamForEventProvider(widget.event.id));
      if (!mounted) return;
      showSnack(context, 'Stream ended');
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------- Viewer ----------------

  Future<void> _getPass() async {
    final stream = _stream;
    if (stream == null) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(livestreamRepositoryProvider);
      final pass = await repo.purchase(stream.id);
      if (pass case StreamPassPaymentRequired(:final clientSecret, :final paymentIntentId)) {
        final outcome = await ref.read(paymentGatewayProvider).collect(clientSecret: clientSecret);
        if (outcome == PaymentOutcome.cancelled) return;
        await repo.confirmPurchase(livestreamId: stream.id, paymentIntentId: paymentIntentId);
      }
      final granted = Livestream(
        id: stream.id,
        eventId: stream.eventId,
        status: stream.status,
        price: stream.price,
        hasAccess: true,
        viewCount: stream.viewCount,
      );
      if (mounted) setState(() => _stream = granted);
      await _watch(granted);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _watch(Livestream stream) async {
    if (_viewer != null || _startingViewer) return;
    _startingViewer = true;
    try {
      final joinInfo = await ref.read(livestreamRepositoryProvider).joinInfo(stream.id);
      if (!mounted) return;
      final viewer = ref.read(liveSessionFactoryProvider).viewer(stream.id, joinInfo);
      _viewer = viewer;
      await viewer.join();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      _startingViewer = false;
    }
    if (mounted) setState(() {});
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final host = _isHost;
    final stream = _stream;
    final live = host ? _broadcasting : (stream?.isLive ?? false);
    final watching = !host && _viewer != null;
    final isDemo = ref.watch(demoModeProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        _Surface(
          event: e,
          broadcast: _broadcast,
          viewer: _viewer,
          isHostLive: host && _broadcasting,
          isDemo: isDemo,
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                stops: const [0, 0.35, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _TopBar(event: e, live: live, viewerCount: _broadcast?.viewerCount ?? _viewer?.viewerCount),
              if (host && _broadcasting && _onAirSince != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _OnAirTimer(since: _onAirSince!),
                ),
              const Spacer(),
              if ((host && _broadcasting) || watching)
                _ChatOverlay(eventId: e.id)
              else
                _Gate(
                  host: host,
                  stream: stream,
                  busy: _busy,
                  event: e,
                  passPrice: _passPrice,
                  onStart: _goLive,
                  onPurchase: _getPass,
                ),
              if (host && _broadcasting && _broadcast != null)
                _HostControls(broadcast: _broadcast!, busy: _busy, onEnd: _end),
            ],
          ),
        ),
      ],
    );
  }
}

/// Video when available, otherwise the event cover as a backdrop.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.event,
    required this.broadcast,
    required this.viewer,
    required this.isHostLive,
    required this.isDemo,
  });

  final Event event;
  final LiveBroadcast? broadcast;
  final LiveViewer? viewer;
  final bool isHostLive;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final backdrop = Stack(
      fit: StackFit.expand,
      children: [
        AppImage(event.coverImage, placeholderSeed: event.name),
        ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
      ],
    );
    final camera = broadcast?.cameraTrack;
    if (isHostLive && camera != null) return VideoTrackRenderer(camera, fit: VideoViewFit.cover);
    final v = viewer;
    if (v == null) return backdrop;
    return ValueListenableBuilder<ViewerState>(
      valueListenable: v.state,
      builder: (context, state, _) {
        final VideoTrack? video = v.remoteVideo.value;
        if (state == ViewerState.playing && video != null) {
          return VideoTrackRenderer(video, fit: VideoViewFit.cover);
        }
        final message = switch (state) {
          ViewerState.hostLeft => 'The host paused the broadcast.\nStay here — it resumes automatically.',
          ViewerState.waitingForHost when isDemo =>
            'Demo mode has no live host.\nOn a real server, the host\'s camera plays here.',
          ViewerState.waitingForHost => "Waiting for the host's camera…",
          _ => 'Connecting to the broadcast…',
        };
        return Stack(
          fit: StackFit.expand,
          children: [
            backdrop,
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state != ViewerState.hostLeft && !isDemo)
                    const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.event, required this.live, required this.viewerCount});

  final Event event;
  final bool live;
  final ValueNotifier<int>? viewerCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          UserAvatar(name: event.organizerName ?? event.name, url: event.organizerPic, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                Text(event.organizerName ?? 'Host',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              ],
            ),
          ),
          if (live)
            viewerCount == null
                ? const LiveBadge()
                : ValueListenableBuilder<int>(
                    valueListenable: viewerCount!,
                    builder: (_, count, _) => LiveBadge(viewers: Fmt.compact(count)),
                  ),
        ],
      ),
    );
  }
}

class _OnAirTimer extends StatelessWidget {
  const _OnAirTimer({required this.since});

  final DateTime since;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (_, _) {
        final d = DateTime.now().difference(since);
        final text = '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
        return StatusChip(label: 'On air $text', color: Colors.white, icon: Icons.fiber_manual_record);
      },
    );
  }
}

class _HostControls extends StatelessWidget {
  const _HostControls({required this.broadcast, required this.busy, required this.onEnd});

  final LiveBroadcast broadcast;
  final bool busy;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: broadcast.micEnabled,
            builder: (_, enabled, _) => _RoundButton(
              icon: enabled ? Icons.mic_rounded : Icons.mic_off_rounded,
              color: enabled ? null : AppColors.live,
              onTap: broadcast.toggleMic,
            ),
          ),
          const SizedBox(width: 12),
          _RoundButton(icon: Icons.cameraswitch_rounded, onTap: broadcast.switchCamera),
          const Spacer(),
          FilledButton.icon(
            onPressed: busy ? null : onEnd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.live,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('End'),
          ),
        ],
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({
    required this.host,
    required this.stream,
    required this.busy,
    required this.event,
    required this.passPrice,
    required this.onStart,
    required this.onPurchase,
  });

  final bool host;
  final Livestream? stream;
  final bool busy;
  final Event event;
  final TextEditingController passPrice;
  final VoidCallback onStart;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final live = stream?.isLive ?? false;
    final price = stream?.price ?? 0;
    final (icon, title, body, action, onTap) = switch ((host, live)) {
      (true, _) => (
          Icons.videocam_rounded,
          'Ready to go live?',
          'Guests can watch your camera and chat in real time.',
          'Start broadcast',
          onStart,
        ),
      (false, true) => (
          Icons.live_tv_rounded,
          'This event is live',
          price > 0
              ? 'Get a stream pass for ${Fmt.money(price)} to watch and chat with other guests.'
              : 'Join the broadcast and chat with other guests in real time.',
          price > 0 ? 'Get stream pass · ${Fmt.money(price)}' : 'Watch now',
          onPurchase,
        ),
      (false, false) => (
          Icons.schedule_rounded,
          "This event isn't live yet",
          'The host will go live on ${Fmt.date(event.date)} at ${Fmt.time(event.startTime)}.',
          null,
          null,
        ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          if (host) ...[
            const SizedBox(height: 20),
            TextField(
              controller: passPrice,
              // A stream's price is fixed once it exists: guests may have paid it.
              enabled: stream == null && !busy,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Stream pass price (leave empty for free)',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.12),
                prefixIcon: const Icon(Icons.sell_rounded, color: Colors.white70),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            PrimaryButton(label: action, loading: busy, onPressed: onTap),
          ],
        ],
      ),
    );
  }
}

class _ChatOverlay extends ConsumerWidget {
  const _ChatOverlay({required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(eventChatProvider(eventId)).value ?? const [];
    final recent = messages.length > 6 ? messages.sublist(messages.length - 6) : messages;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(name: m.authorName, url: m.authorAvatar, size: 26),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(14)),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                          text: '${m.authorName}  ',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        TextSpan(text: m.message, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ])),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          _LiveInput(eventId: eventId),
        ],
      ),
    );
  }
}

class _LiveInput extends ConsumerStatefulWidget {
  const _LiveInput({required this.eventId});

  final int eventId;

  @override
  ConsumerState<_LiveInput> createState() => _LiveInputState();
}

class _LiveInputState extends ConsumerState<_LiveInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await ref.read(eventChatProvider(widget.eventId).notifier).send(text);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'Say something…',
              hintStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: Colors.white38),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _RoundButton(icon: Icons.send_rounded, onTap: _send),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: IconButton(onPressed: onTap, icon: Icon(icon, color: color ?? Colors.white)),
    );
  }
}
