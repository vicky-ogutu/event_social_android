import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/image_picking.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/vendor.dart';
import '../providers/vendor_providers.dart';
import 'vendor_detail_screen.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  bool _uploading = false;

  Future<void> _upload() async {
    final path = await pickImagePath();
    if (path == null || !mounted) return;
    final caption = await _askCaption();
    if (!mounted) return;
    setState(() => _uploading = true);
    try {
      await ref.read(vendorRepositoryProvider).uploadPortfolio(path, caption: caption);
      ref.invalidate(myPortfolioProvider);
      if (mounted) showSnack(context, 'Added to your portfolio');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _askCaption() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a caption'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Garden wedding, June'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim().isEmpty ? null : controller.text.trim()),
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(myPortfolioProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _upload,
        icon: _uploading
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_photo_alternate_rounded),
        label: Text(_uploading ? 'Uploading…' : 'Add photo'),
      ),
      body: AsyncValueView(
        value: portfolio,
        onRetry: () => ref.invalidate(myPortfolioProvider),
        data: (List<PortfolioItem> items) => RefreshIndicator(
          onRefresh: () => ref.refresh(myPortfolioProvider.future),
          child: items.isEmpty
              ? ListView(children: [
                  EmptyState(
                    icon: Icons.photo_library_rounded,
                    title: 'Showcase your best work',
                    message: 'Vendors with 6+ portfolio photos receive more booking requests.',
                    actionLabel: 'Add photo',
                    onAction: _upload,
                  ),
                ])
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => showPortfolioViewer(context, items, i),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'portfolio-${items[i].id}',
                          child: AppImage(items[i].mediaUrl, borderRadius: BorderRadius.circular(16)),
                        ),
                        if (items[i].caption != null)
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                              child: Text(items[i].caption!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
