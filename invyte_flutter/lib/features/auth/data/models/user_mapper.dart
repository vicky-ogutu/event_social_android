import '../../../../core/utils/json.dart';
import '../../domain/entities/user.dart';

abstract final class UserMapper {
  static User fromJson(Json json) {
    final vendor = json['vendor'] is Map ? asJson(json['vendor']) : null;
    return User(
      id: asInt(json['id']),
      uuid: asString(json['uuid']),
      email: asString(json['email']),
      fullName: asString(json['full_name'], 'Invyte member'),
      role: UserRole.parse(asStringOrNull(json['user_type'])),
      phone: asStringOrNull(json['phone']),
      profilePicture: asStringOrNull(json['profile_picture']),
      bio: asStringOrNull(json['bio']),
      isVerified: asBool(json['is_verified']),
      rating: asDouble(json['rating']),
      reviewCount: asInt(json['review_count']),
      walletBalance: asDouble(json['wallet_balance']),
      totalSpent: asDouble(json['total_spent']),
      businessName: asStringOrNull(vendor?['business_name']),
      vendorApproved: vendor == null ? null : asBool(vendor['is_approved']),
      totalEarnings: asDoubleOrNull(vendor?['total_earnings']),
      completedJobs: asIntOrNull(vendor?['completed_jobs']),
    );
  }

  /// Inverse of [fromJson]; used to persist the user locally.
  static Json toJson(User user) => {
        'id': user.id,
        'uuid': user.uuid,
        'email': user.email,
        'full_name': user.fullName,
        'user_type': user.role.name,
        'phone': user.phone,
        'profile_picture': user.profilePicture,
        'bio': user.bio,
        'is_verified': user.isVerified,
        'rating': user.rating,
        'review_count': user.reviewCount,
        'wallet_balance': user.walletBalance,
        'total_spent': user.totalSpent,
        if (user.isVendor)
          'vendor': {
            'business_name': user.businessName,
            'is_approved': user.vendorApproved,
            'total_earnings': user.totalEarnings,
            'completed_jobs': user.completedJobs,
          },
      };

  /// Profile endpoints return either `{ user: {...} }` or the user itself.
  static User fromEnvelope(Object? data) {
    final json = asJson(data);
    return fromJson(json['user'] is Map ? asJson(json['user']) : json);
  }
}
