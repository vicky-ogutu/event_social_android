class ServiceCategory {
  const ServiceCategory({required this.id, required this.name, required this.slug, this.description});

  final int id;
  final String name;
  final String slug;
  final String? description;
}

class VendorService {
  const VendorService({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.name,
    required this.basePrice,
    this.description,
    this.priceUnit,
    this.categoryName,
    this.isActive = true,
  });

  final int id;
  final int vendorId;
  final int categoryId;
  final String name;
  final String? description;
  final double basePrice;
  final String? priceUnit;
  final String? categoryName;
  final bool isActive;

  String get unitLabel => priceUnit == null || priceUnit!.isEmpty ? '' : '/ $priceUnit';
}

class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.vendorId,
    required this.mediaUrl,
    this.mediaType = 'image',
    this.title,
    this.caption,
    this.likesCount = 0,
    this.isCover = false,
  });

  final int id;
  final int vendorId;
  final String mediaUrl;
  final String mediaType;
  final String? title;
  final String? caption;
  final int likesCount;
  final bool isCover;

  bool get isVideo => mediaType == 'video';
}

/// A vendor as seen by customers browsing the marketplace.
class Vendor {
  const Vendor({
    required this.id,
    required this.userId,
    required this.businessName,
    this.address,
    this.phone,
    this.email,
    this.category,
    this.description,
    this.isApproved = false,
    this.totalEarnings = 0,
    this.completedJobs = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.ownerName,
    this.profilePicture,
    this.coverImage,
    this.services = const [],
    this.portfolio = const [],
  });

  final int id;
  final int userId;
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? category;
  final String? description;
  final bool isApproved;
  final double totalEarnings;
  final int completedJobs;
  final double rating;
  final int reviewCount;
  final String? ownerName;
  final String? profilePicture;
  final String? coverImage;
  final List<VendorService> services;
  final List<PortfolioItem> portfolio;

  String? get heroImage => coverImage ?? (portfolio.isEmpty ? null : portfolio.first.mediaUrl);

  double? get startingPrice => services.isEmpty
      ? null
      : services.map((s) => s.basePrice).reduce((a, b) => a < b ? a : b);
}

/// The signed-in vendor's own business profile.
class VendorProfile {
  const VendorProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.address,
    this.phone,
    this.description,
    this.isApproved = false,
    this.rating = 0,
    this.reviewCount = 0,
  });

  final int id;
  final int userId;
  final String businessName;
  final String? address;
  final String? phone;
  final String? description;
  final bool isApproved;
  final double rating;
  final int reviewCount;
}

class VendorProfileDraft {
  const VendorProfileDraft({
    required this.businessName,
    required this.address,
    required this.phone,
    this.description,
  });

  final String businessName;
  final String address;
  final String phone;
  final String? description;
}

class ServiceDraft {
  const ServiceDraft({
    required this.categoryId,
    required this.name,
    required this.basePrice,
    this.description,
  });

  final int categoryId;
  final String name;
  final String? description;
  final double basePrice;
}

class VendorQuery {
  const VendorQuery({this.search, this.category});

  final String? search;
  final String? category;

  @override
  bool operator ==(Object other) => other is VendorQuery && other.search == search && other.category == category;

  @override
  int get hashCode => Object.hash(search, category);
}
