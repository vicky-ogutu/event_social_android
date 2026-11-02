import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invyte/core/di/core_providers.dart';
import 'package:invyte/core/error/failure.dart';
import 'package:invyte/features/auth/domain/entities/user.dart';
import 'package:invyte/features/auth/presentation/providers/auth_providers.dart';
import 'package:invyte/features/bookings/domain/entities/booking.dart';
import 'package:invyte/features/bookings/presentation/providers/booking_providers.dart';
import 'package:invyte/features/events/presentation/providers/event_providers.dart';
import 'package:invyte/features/livestream/domain/entities/livestream.dart';
import 'package:invyte/features/livestream/presentation/providers/livestream_providers.dart';
import 'package:invyte/features/vendors/presentation/providers/vendor_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:invyte/core/storage/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end through providers → repositories → data sources → ApiClient,
/// with the in-memory demo backend as the transport.
void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = await TokenStore.open(prefs);
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
      ],
      retry: (_, _) => null,
    );
  });

  tearDown(() => container.dispose());

  test('customer demo: browse, book and pay; vendor sees and accepts it', () async {
    final auth = container.read(authControllerProvider.notifier);

    await auth.startDemo(UserRole.consumer);
    expect(container.read(currentUserProvider)?.fullName, 'Amara Okafor');
    expect(container.read(demoModeProvider), isTrue);

    final events = await container.read(myEventsProvider.future);
    expect(events, isNotEmpty);

    final vendor = await container.read(vendorDetailProvider(1).future);
    final service = vendor.services.first;

    final bookings = container.read(bookingRepositoryProvider);
    final booking = await bookings.create(BookingDraft(
      eventId: events.first.id,
      serviceId: service.id,
      serviceDate: DateTime.now().add(const Duration(days: 30)),
      serviceTime: '15:00:00',
      quantity: 2,
    ));
    expect(booking.status, BookingStatus.pending);
    expect(booking.agreedPrice, service.basePrice * 2);
    expect(booking.totalAmount, greaterThan(booking.agreedPrice));

    final intent = await bookings.createPaymentIntent(booking.id);
    expect(intent.clientSecret, isNotEmpty);
    expect((await bookings.getBooking(booking.id)).isPaid, isFalse);
    final paid = await bookings.confirmPayment(intent.id);
    expect(paid.isPaid, isTrue);

    // Same process, now as the vendor.
    await auth.logout();
    expect(container.read(currentUserProvider), isNull);
    await auth.startDemo(UserRole.vendor);
    expect(container.read(currentUserProvider)?.isVendor, isTrue);

    final incoming = await container.read(vendorBookingsProvider.future);
    expect(incoming.any((b) => b.id == booking.id), isTrue);

    await container.read(bookingRepositoryProvider).accept(booking.id);
    final updated = await container.read(bookingRepositoryProvider).getBooking(booking.id);
    expect(updated.status, BookingStatus.confirmed);
  });

  test('viewer buys a stream pass; host goes live and ends a stream', () async {
    final auth = container.read(authControllerProvider.notifier);
    await auth.startDemo(UserRole.consumer);
    final live = container.read(livestreamRepositoryProvider);

    // Someone else's paid, live stream.
    final jazz = await live.forEvent(4);
    expect(jazz?.isLive, isTrue);
    expect(jazz?.hasAccess, isFalse);
    final pass = await live.purchase(jazz!.id);
    expect(pass, isA<StreamPassPaymentRequired>());
    await live.confirmPurchase(
      livestreamId: jazz.id,
      paymentIntentId: (pass as StreamPassPaymentRequired).paymentIntentId,
    );
    expect((await live.forEvent(4))?.hasAccess, isTrue);

    // The user's own event: prepare → start → end.
    final myEvent = (await container.read(myEventsProvider.future)).first;
    final stream = await live.prepare(myEvent.id);
    expect(stream.isHost, isTrue);
    expect(stream.id, isNot(myEvent.id), reason: 'livestream ids are not event ids');
    await live.start(stream.id);
    expect((await container.read(eventRepositoryProvider).getEvent(myEvent.id)).isLive, isTrue);
    await live.end(stream.id);
    expect(await live.forEvent(myEvent.id), isNull);
  });

  test('wrong credentials surface a readable error', () async {
    container.read(demoModeProvider.notifier).set(true);
    await expectLater(
      container.read(authRepositoryProvider).login(email: 'amara@invyte.app', password: 'nope'),
      throwsA(predicate((e) => e.toString() == 'Invalid email or password.')),
    );
  });

  test('session is persisted to shared preferences and restored', () async {
    await container.read(authControllerProvider.notifier).startDemo(UserRole.consumer);

    final prefs = container.read(sharedPreferencesProvider);
    final restored = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(await TokenStore.open(prefs)),
    ]);
    addTearDown(restored.dispose);

    expect(restored.read(currentUserProvider)?.email, 'amara@invyte.app');
    expect(restored.read(demoModeProvider), isTrue);
  });

  test('joining a public event records it and hides the budget', () async {
    await container.read(authControllerProvider.notifier).startDemo(UserRole.consumer);
    final repo = container.read(eventRepositoryProvider);

    final before = await repo.getEvent(7);
    expect(before.hasJoined, isFalse);
    expect(before.budget, isNull);
    expect((await repo.myEvents()).items.map((e) => e.id), isNot(contains(7)));

    await repo.join(7);

    expect((await repo.getEvent(7)).hasJoined, isTrue);
    expect((await repo.myEvents()).items.map((e) => e.id), contains(7));
  });

  test('guest joins a private event with only its code', () async {
    await container.read(authControllerProvider.notifier).startDemo(UserRole.consumer);
    final repo = container.read(eventRepositoryProvider);

    final discovered = await repo.discover();
    expect(discovered.items.where((e) => e.id == 8), isEmpty);
    await expectLater(repo.getEvent(8), throwsA(isA<Failure>()));
    await expectLater(repo.joinByCode('NOPE99'), throwsA(isA<Failure>()));

    final joined = await repo.joinByCode(' engage ');
    expect(joined.id, 8);
    expect(joined.accessCode, isNull);
    expect((await repo.getEvent(8)).name, 'Kofi & Ama Engagement');
    expect((await repo.myEvents()).items.map((e) => e.id), contains(8));
  });
}
