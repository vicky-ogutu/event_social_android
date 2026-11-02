enum UserRole {
  consumer,
  vendor;

  static UserRole parse(String? value) => value == 'vendor' ? vendor : consumer;

  String get label => switch (this) {
        consumer => 'Event host',
        vendor => 'Vendor',
      };
}

class User {
  const User({
    required this.id,
    required this.uuid,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.profilePicture,
    this.bio,
    this.isVerified = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.walletBalance = 0,
    this.totalSpent = 0,
    this.businessName,
    this.vendorApproved,
    this.totalEarnings,
    this.completedJobs,
  });

  final int id;
  final String uuid;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? profilePicture;
  final String? bio;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final double walletBalance;
  final double totalSpent;

  // Vendor-only summary
  final String? businessName;
  final bool? vendorApproved;
  final double? totalEarnings;
  final int? completedJobs;

  bool get isVendor => role == UserRole.vendor;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  String get displayName => isVendor && (businessName?.isNotEmpty ?? false) ? businessName! : fullName;

  User copyWith({String? fullName, String? bio, String? profilePicture}) => User(
        id: id,
        uuid: uuid,
        email: email,
        fullName: fullName ?? this.fullName,
        role: role,
        phone: phone,
        profilePicture: profilePicture ?? this.profilePicture,
        bio: bio ?? this.bio,
        isVerified: isVerified,
        rating: rating,
        reviewCount: reviewCount,
        walletBalance: walletBalance,
        totalSpent: totalSpent,
        businessName: businessName,
        vendorApproved: vendorApproved,
        totalEarnings: totalEarnings,
        completedJobs: completedJobs,
      );
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user, this.refreshToken});

  final String accessToken;
  final String? refreshToken;
  final User user;
}

/// Outcome of sign-up: either signed in, or an emailed code must be entered.
sealed class RegistrationResult {
  const RegistrationResult();
}

class RegistrationComplete extends RegistrationResult {
  const RegistrationComplete(this.session);
  final AuthSession session;
}

class VerificationRequired extends RegistrationResult {
  const VerificationRequired(this.email);
  final String email;
}

/// Error codes the auth API returns in `Failure.code`.
abstract final class AuthErrorCodes {
  static const emailNotVerified = 'EMAIL_NOT_VERIFIED';
  static const invalidCode = 'INVALID_CODE';
  static const rateLimited = 'RATE_LIMITED';
}
