import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_picking.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../bookings/presentation/providers/booking_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _changePhoto() async {
    final path = await pickImagePath(maxWidth: 800);
    if (path == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(profileActionsProvider).uploadAvatar(path);
      if (mounted) showSnack(context, 'Profile photo updated');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmAction(context, title: 'Sign out?', message: 'You can sign back in any time.', confirmLabel: 'Sign out');
    if (ok) await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _logoutEverywhere() async {
    final ok = await confirmAction(
      context,
      title: 'Sign out everywhere?',
      message: 'This ends your session on every phone and tablet, including this one. '
          'Use it if you lost a device or think someone else has access.',
      confirmLabel: 'Sign out all',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(authControllerProvider.notifier).logoutEverywhere();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  void _chooseTheme() {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (mode) {
            if (mode != null) ref.read(themeModeProvider.notifier).set(mode);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (mode, label, icon) in [
                (ThemeMode.system, 'Match system', Icons.brightness_auto_rounded),
                (ThemeMode.light, 'Light', Icons.light_mode_rounded),
                (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
              ])
                RadioListTile<ThemeMode>(
                  value: mode,
                  title: Text(label),
                  secondary: Icon(icon),
                  activeColor: AppColors.primary,
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final isDemo = ref.watch(demoModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(user: user, uploading: _uploading, onPhotoTap: _changePhoto),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList.list(
              children: [
                user.isVendor ? const _VendorStats() : const _ConsumerStats(),
                const SizedBox(height: 20),
                _MenuGroup(children: [
                  if (!user.isVendor) ...[
                    _MenuItem(icon: Icons.event_rounded, label: 'My events', onTap: () => context.push(Routes.myEvents)),
                    _MenuItem(
                        icon: Icons.receipt_long_rounded, label: 'My bookings', onTap: () => context.push(Routes.myBookings)),
                  ] else ...[
                    _MenuItem(
                        icon: Icons.storefront_rounded,
                        label: 'Business profile',
                        onTap: () => context.push(Routes.vendorBusiness)),
                    _MenuItem(
                        icon: Icons.design_services_rounded,
                        label: 'Services & pricing',
                        onTap: () => context.push(Routes.vendorServices)),
                    _MenuItem(
                        icon: Icons.photo_library_rounded,
                        label: 'Portfolio',
                        onTap: () => context.push(Routes.vendorPortfolio)),
                  ],
                  _MenuItem(icon: Icons.live_tv_rounded, label: 'Go live', onTap: () => context.push(Routes.goLive)),
                ]),
                const SizedBox(height: 16),
                _MenuGroup(children: [
                  _MenuItem(
                      icon: Icons.person_outline_rounded, label: 'Edit profile', onTap: () => context.push(Routes.editProfile)),
                  _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change password',
                      onTap: isDemo
                          ? () => showSnack(context, 'Password changes are disabled in demo mode.')
                          : () => context.push(Routes.changePassword)),
                  _MenuItem(icon: Icons.palette_outlined, label: 'Appearance', onTap: _chooseTheme),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About ${AppConfig.appName}',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: AppConfig.appName,
                      applicationVersion: '1.0.0',
                      applicationIcon: const BrandLogo(size: 40),
                      applicationLegalese: AppConfig.tagline,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _MenuGroup(children: [
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: isDemo ? 'Exit demo' : 'Sign out',
                    color: AppColors.danger,
                    onTap: _logout,
                  ),
                  if (!isDemo)
                    _MenuItem(
                      icon: Icons.devices_other_rounded,
                      label: 'Sign out of all devices',
                      color: AppColors.danger,
                      onTap: _logoutEverywhere,
                    ),
                ]),
                const SizedBox(height: 24),
                Center(
                  child: Text('${AppConfig.appName} v1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.uploading, required this.onPhotoTap});

  final User user;
  final bool uploading;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.nightGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              GestureDetector(
                onTap: uploading ? null : onPhotoTap,
                child: Stack(
                  children: [
                    UserAvatar(name: user.fullName, url: user.profilePicture, size: 96, ring: true),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: uploading
                            ? const SizedBox.square(
                                dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(user.displayName,
                        textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 10),
              StatusChip(
                label: user.role.label,
                icon: user.isVendor ? Icons.storefront_rounded : Icons.celebration_rounded,
                color: Colors.white,
              ),
              if (user.bio != null) ...[
                const SizedBox(height: 14),
                Text(user.bio!,
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsumerStats extends ConsumerWidget {
  const _ConsumerStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(myEventsProvider).value;
    final bookings = ref.watch(myBookingsProvider).value;
    final spent = bookings?.fold<double>(0, (sum, b) => sum + b.amountPaid);
    return Row(
      children: [
        Expanded(child: StatTile(label: 'Events', value: '${events?.length ?? '–'}', icon: Icons.event_rounded)),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            label: 'Bookings',
            value: '${bookings?.length ?? '–'}',
            icon: Icons.receipt_long_rounded,
            color: AppColors.violet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            label: 'Spent',
            value: spent == null ? '–' : Fmt.moneyCompact(spent),
            icon: Icons.payments_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _VendorStats extends ConsumerWidget {
  const _VendorStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(vendorStatsProvider).value;
    final user = ref.watch(currentUserProvider);
    return Row(
      children: [
        Expanded(
          child: StatTile(
            label: 'Rating',
            value: (user?.rating ?? 0) > 0 ? user!.rating.toStringAsFixed(1) : 'New',
            icon: Icons.star_rounded,
            color: AppColors.star,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            label: 'Completed',
            value: '${stats?.completed ?? user?.completedJobs ?? '–'}',
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            label: 'Earned',
            value: stats == null ? '–' : Fmt.moneyCompact(stats.revenue),
            icon: Icons.payments_rounded,
          ),
        ),
      ],
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 56),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      trailing: color == null ? const Icon(Icons.chevron_right_rounded) : null,
    );
  }
}
