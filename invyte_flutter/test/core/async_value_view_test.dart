import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invyte/core/widgets/state_views.dart';

void main() {
  Future<void> pump(WidgetTester tester, AsyncValue<String?> value) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueView<String?>(value: value, data: (v) => Text('data: $v')),
          ),
        ),
      );

  testWidgets('renders data when the loaded value is null', (tester) async {
    await pump(tester, const AsyncData<String?>(null));
    expect(find.text('data: null'), findsOneWidget);
    expect(find.byType(SkeletonList), findsNothing);
  });

  testWidgets('renders a non-null value', (tester) async {
    await pump(tester, const AsyncData<String?>('x'));
    expect(find.text('data: x'), findsOneWidget);
  });

  testWidgets('shows the skeleton while loading', (tester) async {
    await pump(tester, const AsyncLoading<String?>());
    expect(find.byType(SkeletonList), findsOneWidget);
  });

  testWidgets('shows the error state on failure', (tester) async {
    await pump(tester, const AsyncError<String?>('boom', StackTrace.empty));
    expect(find.text('Something went sideways'), findsOneWidget);
  });
}
