import '../../../../core/models/paginated.dart';
import '../entities/vendor.dart';

/// Marketplace discovery (customers) and business self-service (vendors).
abstract interface class VendorRepository {
  // ---- Discovery ----
  Future<List<ServiceCategory>> categories();

  Future<Paginated<Vendor>> search({String? query, String? category, double? minRating, int page = 1});

  Future<Vendor> getVendor(int id);

  Future<List<VendorService>> servicesOf(int vendorId);

  // ---- Self-service ----
  /// Returns `null` when the vendor hasn't created a business profile yet.
  Future<VendorProfile?> myProfile();

  Future<VendorProfile> saveProfile(VendorProfileDraft draft, {required bool exists});

  /// Whether Stripe can send this vendor money.
  Future<bool> payoutsReady();

  /// Returns the Stripe page where the vendor sets up payouts.
  Future<String> startPayoutOnboarding();

  Future<List<VendorService>> myServices();

  Future<VendorService> createService(ServiceDraft draft);

  Future<VendorService> updateService(int id, ServiceDraft draft);

  Future<void> deleteService(int id);

  Future<List<PortfolioItem>> myPortfolio();

  Future<void> uploadPortfolio(String filePath, {String? caption});
}
