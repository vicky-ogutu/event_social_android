import '../../../auth/domain/entities/user.dart';

abstract interface class ProfileRepository {
  Future<User> updateProfile({required String fullName, String? bio});

  Future<void> changePassword({required String currentPassword, required String newPassword});

  Future<User> uploadAvatar(String filePath);
}
