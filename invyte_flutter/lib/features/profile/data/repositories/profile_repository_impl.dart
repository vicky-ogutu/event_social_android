import '../../../../core/error/failure.dart';
import '../../../../core/storage/token_store.dart';
import '../../../../core/utils/json.dart';
import '../../../auth/data/models/user_mapper.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote, {required this.current, required TokenStore tokens}) : _tokens = tokens;

  final ProfileRemoteDataSource _remote;
  final TokenStore _tokens;

  /// Used to fill gaps when an endpoint returns a partial user.
  final User current;

  @override
  Future<User> updateProfile({required String fullName, String? bio}) => guard(() async {
        final data = await _remote.updateProfile(fullName.trim(), bio?.trim());
        return _merge(data).copyWith(fullName: fullName.trim(), bio: bio?.trim());
      });

  /// The server signs out every other device and returns a fresh session for
  /// this one, which replaces the now-revoked tokens.
  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) => guard(() async {
        final data = asJson(await _remote.changePassword(currentPassword, newPassword));
        final access = asStringOrNull(data['access_token'] ?? data['token']);
        if (access != null) {
          await _tokens.save(accessToken: access, refreshToken: asStringOrNull(data['refresh_token']));
        }
      });

  @override
  Future<User> uploadAvatar(String filePath) => guard(() async => _merge(await _remote.uploadAvatar(filePath)));

  User _merge(Object? data) {
    if (data is! Map) return current;
    final updated = UserMapper.fromEnvelope(data);
    if (updated.id == 0) {
      final picture = data['profile_picture'] ?? data['avatar_url'];
      return picture is String ? current.copyWith(profilePicture: picture) : current;
    }
    return updated;
  }
}
