import '../../../../core/network/api_client.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Object?> updateProfile(String fullName, String? bio) =>
      _api.put('api/users/profile', body: {'full_name': fullName, 'bio': bio});

  Future<Object?> changePassword(String oldPassword, String newPassword) => _api.put(
        'api/users/password',
        body: {'old_password': oldPassword, 'new_password': newPassword},
      );

  Future<Object?> uploadAvatar(String filePath) =>
      _api.upload('api/users/upload-avatar', fileField: 'avatar', filePath: filePath);
}
