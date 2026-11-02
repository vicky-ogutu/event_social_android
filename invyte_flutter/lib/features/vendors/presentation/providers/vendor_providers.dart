import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/datasources/vendor_remote_data_source.dart';
import '../../data/repositories/vendor_repository_impl.dart';
import '../../domain/entities/vendor.dart';
import '../../domain/repositories/vendor_repository.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return VendorRepositoryImpl(VendorRemoteDataSource(ref.watch(apiClientProvider)));
});

// ---- Discovery ----

final categoriesProvider = FutureProvider<List<ServiceCategory>>(
  (ref) => ref.watch(vendorRepositoryProvider).categories(),
);

final vendorSearchProvider = FutureProvider.family<List<Vendor>, VendorQuery>((ref, query) async {
  final page = await ref.watch(vendorRepositoryProvider).search(query: query.search, category: query.category);
  return page.items;
});

final topVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final page = await ref.watch(vendorRepositoryProvider).search(minRating: 4.5);
  return page.items.take(8).toList();
});

final vendorDetailProvider = FutureProvider.autoDispose.family<Vendor, int>(
  (ref, id) => ref.watch(vendorRepositoryProvider).getVendor(id),
);

final vendorServicesProvider = FutureProvider.autoDispose.family<List<VendorService>, int>(
  (ref, vendorId) => ref.watch(vendorRepositoryProvider).servicesOf(vendorId),
);

// ---- Vendor self-service ----

final myVendorProfileProvider = FutureProvider<VendorProfile?>(
  (ref) => ref.watch(vendorRepositoryProvider).myProfile(),
);

final payoutsReadyProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(vendorRepositoryProvider).payoutsReady(),
);

final myServicesProvider = FutureProvider<List<VendorService>>(
  (ref) => ref.watch(vendorRepositoryProvider).myServices(),
);

final myPortfolioProvider = FutureProvider<List<PortfolioItem>>(
  (ref) => ref.watch(vendorRepositoryProvider).myPortfolio(),
);
