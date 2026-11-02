import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('Profile requires a signed-in user');
  return ProfileRepositoryImpl(
    ProfileRemoteDataSource(ref.watch(apiClientProvider)),
    current: user,
    tokens: ref.watch(tokenStoreProvider),
  );
});

/// Profile mutations that also keep the cached session user in sync.
final profileActionsProvider = Provider<ProfileActions>(ProfileActions.new);

class ProfileActions {
  const ProfileActions(this._ref);

  final Ref _ref;

  ProfileRepository get _repository => _ref.read(profileRepositoryProvider);

  Future<void> updateProfile({required String fullName, String? bio}) async {
    final user = await _repository.updateProfile(fullName: fullName, bio: bio);
    await _ref.read(authControllerProvider.notifier).updateUser(user);
  }

  Future<void> uploadAvatar(String path) async {
    final user = await _repository.uploadAvatar(path);
    await _ref.read(authControllerProvider.notifier).updateUser(user);
  }

  Future<void> changePassword({required String current, required String next}) =>
      _repository.changePassword(currentPassword: current, newPassword: next);
}
