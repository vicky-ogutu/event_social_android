import '../../../../core/error/failure.dart';
import '../../../../core/models/paginated.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/vendor.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../datasources/vendor_remote_data_source.dart';
import '../models/vendor_mapper.dart';

class VendorRepositoryImpl implements VendorRepository {
  const VendorRepositoryImpl(this._remote);

  final VendorRemoteDataSource _remote;

  @override
  Future<List<ServiceCategory>> categories() =>
      guard(() async => asList(await _remote.categories(), VendorMapper.category));

  @override
  Future<Paginated<Vendor>> search({String? query, String? category, double? minRating, int page = 1}) =>
      guard(() async => VendorMapper.page(
          await _remote.list(search: query, category: category, minRating: minRating, page: page)));

  @override
  Future<Vendor> getVendor(int id) => guard(() async => VendorMapper.vendor(await _remote.get(id)));

  @override
  Future<List<VendorService>> servicesOf(int vendorId) =>
      guard(() async => asList(await _remote.servicesOf(vendorId), VendorMapper.service));

  @override
  Future<VendorProfile?> myProfile() async {
    try {
      final json = await guard(_remote.myProfile);
      return json.isEmpty ? null : VendorMapper.profile(json);
    } on Failure catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<VendorProfile> saveProfile(VendorProfileDraft draft, {required bool exists}) => guard(() async {
        final body = VendorMapper.profileToJson(draft);
        final json = exists ? await _remote.updateProfile(body) : await _remote.createProfile(body);
        return VendorMapper.profile(json);
      });

  @override
  Future<List<VendorService>> myServices() =>
      guard(() async => asList(await _remote.myServices(), VendorMapper.service));

  @override
  Future<VendorService> createService(ServiceDraft draft) => guard(
      () async => VendorMapper.service(await _remote.createService(VendorMapper.serviceToJson(draft))));

  @override
  Future<VendorService> updateService(int id, ServiceDraft draft) => guard(
      () async => VendorMapper.service(await _remote.updateService(id, VendorMapper.serviceToJson(draft))));

  @override
  Future<void> deleteService(int id) => guard(() => _remote.deleteService(id));

  @override
  Future<List<PortfolioItem>> myPortfolio() =>
      guard(() async => asList(await _remote.myPortfolio(), VendorMapper.portfolioItem));

  @override
  Future<void> uploadPortfolio(String filePath, {String? caption}) =>
      guard(() => _remote.uploadPortfolio(filePath, caption));
}
