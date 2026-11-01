import '../../../../core/models/paginated.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/vendor.dart';

abstract final class VendorMapper {
  static ServiceCategory category(Json json) => ServiceCategory(
        id: asInt(json['id']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        description: asStringOrNull(json['description']),
      );

  static VendorService service(Json json) => VendorService(
        id: asInt(json['id']),
        vendorId: asInt(json['vendor_id']),
        categoryId: asInt(json['category_id']),
        name: asString(json['service_name'], 'Service'),
        description: asStringOrNull(json['description']),
        basePrice: asDouble(json['base_price']),
        priceUnit: asStringOrNull(json['price_unit']),
        categoryName: asStringOrNull(json['category_name']),
        isActive: json['is_active'] == null || asBool(json['is_active']),
      );

  static PortfolioItem portfolioItem(Json json) => PortfolioItem(
        id: asInt(json['id']),
        vendorId: asInt(json['vendor_id']),
        mediaUrl: asString(json['media_url']),
        mediaType: asString(json['media_type'], 'image'),
        title: asStringOrNull(json['title']),
        caption: asStringOrNull(json['caption']),
        likesCount: asInt(json['likes_count']),
        isCover: asBool(json['is_cover']),
      );

  static Vendor vendor(Json json) => Vendor(
        id: asInt(json['id']),
        userId: asInt(json['user_id']),
        businessName: asString(json['business_name'], 'Vendor'),
        address: asStringOrNull(json['business_address'] ?? json['address']),
        phone: asStringOrNull(json['business_phone'] ?? json['phone']),
        email: asStringOrNull(json['business_email']),
        category: asStringOrNull(json['service_category']),
        description: asStringOrNull(json['description']),
        isApproved: asBool(json['is_approved']),
        totalEarnings: asDouble(json['total_earnings']),
        completedJobs: asInt(json['completed_jobs']),
        rating: asDouble(json['rating']),
        reviewCount: asInt(json['review_count']),
        ownerName: asStringOrNull(json['full_name']),
        profilePicture: asStringOrNull(json['profile_picture']),
        coverImage: asStringOrNull(json['cover_image']),
        services: asList(json['services'], service),
        portfolio: asList(json['portfolio'], portfolioItem),
      );

  static Paginated<Vendor> page(Object? data) {
    if (data is List) {
      final items = asList(data, vendor);
      return Paginated(items: items, page: 1, pages: 1, total: items.length);
    }
    final json = asJson(data);
    final items = asList(json['data'] ?? json['vendors'], vendor);
    return Paginated(
      items: items,
      page: asInt(json['page'], 1),
      pages: asInt(json['pages'], 1),
      total: asInt(json['total'], items.length),
    );
  }

  static VendorProfile profile(Json json) => VendorProfile(
        id: asInt(json['id']),
        userId: asInt(json['user_id']),
        businessName: asString(json['business_name']),
        address: asStringOrNull(json['address'] ?? json['business_address']),
        phone: asStringOrNull(json['phone'] ?? json['business_phone']),
        description: asStringOrNull(json['description']),
        isApproved: asBool(json['is_approved']),
        rating: asDouble(json['rating']),
        reviewCount: asInt(json['review_count']),
      );

  static Json profileToJson(VendorProfileDraft draft) => {
        'business_name': draft.businessName,
        'address': draft.address,
        'phone': draft.phone,
        'description': draft.description,
      };

  static Json serviceToJson(ServiceDraft draft) => {
        'category_id': draft.categoryId,
        'service_name': draft.name,
        'description': draft.description,
        'base_price': draft.basePrice,
      };
}
